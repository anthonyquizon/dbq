// filewatch.h - Single file cross-platform file watcher
#include <stddef.h>
#include <stdio.h>

typedef enum {
    FW_MODIFIED = 1,
    FW_CREATED = 2,
    FW_DELETED = 4,
    FW_RENAMED = 8
} fw_event_type;

typedef struct {
    char path[512];
    fw_event_type type;
} fw_event;

typedef struct fw_watcher fw_watcher;

fw_watcher* fw_create(void);
int fw_add(fw_watcher *w, const char *path, int recursive);
fw_event* fw_poll(fw_watcher *w, int timeout_ms);
void fw_destroy(fw_watcher *w);

#if defined(__linux__)
    #include <sys/inotify.h>
    #include <unistd.h>
    #include <poll.h>
    #include <stdlib.h>
    #include <string.h>

    struct fw_watcher {
        int fd;
        fw_event current;
    };

    fw_watcher* fw_create(void) {
        fw_watcher *w = malloc(sizeof(fw_watcher));
        w->fd = inotify_init1(IN_NONBLOCK);
        return w->fd < 0 ? (free(w), NULL) : w;
    }

    int fw_add(fw_watcher *w, const char *path, int recursive) {
        uint32_t mask = IN_MODIFY | IN_CREATE | IN_DELETE | IN_MOVED_TO | IN_MOVED_FROM;
        return inotify_add_watch(w->fd, path, mask) >= 0 ? 0 : -1;
    }

    fw_event* fw_poll(fw_watcher *w, int timeout_ms) {
        struct pollfd pfd = {w->fd, POLLIN, 0};
        if (poll(&pfd, 1, timeout_ms) <= 0) return NULL;
        
        char buf[4096] __attribute__((aligned(__alignof__(struct inotify_event))));
        ssize_t len = read(w->fd, buf, sizeof(buf));
        if (len <= 0) return NULL;
        
        struct inotify_event *e = (struct inotify_event *)buf;
        if (!e->len) return NULL;
        
        w->current.type = 0;
        if (e->mask & IN_MODIFY) w->current.type |= FW_MODIFIED;
        if (e->mask & IN_CREATE) w->current.type |= FW_CREATED;
        if (e->mask & (IN_DELETE | IN_DELETE_SELF)) w->current.type |= FW_DELETED;
        if (e->mask & (IN_MOVED_TO | IN_MOVED_FROM)) w->current.type |= FW_RENAMED;
        
        strncpy(w->current.path, e->name, sizeof(w->current.path) - 1);
        return w->current.type ? &w->current : NULL;
    }

    void fw_destroy(fw_watcher *w) {
        close(w->fd);
        free(w);
    }

#elif defined(__APPLE__)
    #include <CoreServices/CoreServices.h>
    #include <dispatch/dispatch.h>
    #include <pthread.h>

    typedef struct {
        char path[512];
        fw_event_type type;
    } event_queue_item;

    struct fw_watcher {
        FSEventStreamRef stream;
        dispatch_queue_t queue;
        pthread_mutex_t mutex;
        event_queue_item events[64];
        int read_idx, write_idx, count;
        fw_event current;
    };

    static void fs_callback(ConstFSEventStreamRef streamRef, void *info,
                           size_t numEvents, void *eventPaths,
                           const FSEventStreamEventFlags eventFlags[],
                           const FSEventStreamEventId eventIds[]) {
        fw_watcher *w = (fw_watcher *)info;
        char **paths = (char **)eventPaths;

        pthread_mutex_lock(&w->mutex);
        for (size_t i = 0; i < numEvents && w->count < 64; i++) {
            fw_event_type type = 0;
            if (eventFlags[i] & kFSEventStreamEventFlagItemModified) type |= FW_MODIFIED;
            if (eventFlags[i] & kFSEventStreamEventFlagItemCreated) type |= FW_CREATED;
            if (eventFlags[i] & kFSEventStreamEventFlagItemRemoved) type |= FW_DELETED;
            if (eventFlags[i] & kFSEventStreamEventFlagItemRenamed) type |= FW_RENAMED;

            if (type) {
                strncpy(w->events[w->write_idx].path, paths[i], 511);
                w->events[w->write_idx].type = type;
                w->write_idx = (w->write_idx + 1) % 64;
                w->count++;
            }
        }
        pthread_mutex_unlock(&w->mutex);
    }

    fw_watcher* fw_create(void) {
        fw_watcher *w = calloc(1, sizeof(fw_watcher));
        pthread_mutex_init(&w->mutex, NULL);
        w->queue = dispatch_queue_create("filewatch", DISPATCH_QUEUE_SERIAL);
        return w;
    }

    int fw_add(fw_watcher *w, const char *path, int recursive) {
        CFStringRef cfpath = CFStringCreateWithCString(NULL, path, kCFStringEncodingUTF8);
        CFArrayRef paths = CFArrayCreate(NULL, (const void **)&cfpath, 1, NULL);

        FSEventStreamContext ctx = {0, w, NULL, NULL, NULL};
        w->stream = FSEventStreamCreate(NULL, fs_callback, &ctx, paths,
            kFSEventStreamEventIdSinceNow, 0.1,
            kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer);

        CFRelease(paths);
        CFRelease(cfpath);

        if (!w->stream) return -1;

        FSEventStreamSetDispatchQueue(w->stream, w->queue);
        FSEventStreamStart(w->stream);
        return 0;
    }

    fw_event* fw_poll(fw_watcher *w, int timeout_ms) {
        int waited = 0;
        while (waited < timeout_ms) {
            pthread_mutex_lock(&w->mutex);
            if (w->count > 0) {
                w->current = *(fw_event*)&w->events[w->read_idx];
                w->read_idx = (w->read_idx + 1) % 64;
                w->count--;
                pthread_mutex_unlock(&w->mutex);
                return &w->current;
            }
            pthread_mutex_unlock(&w->mutex);
            usleep(10000);
            waited += 10;
        }
        return NULL;
    }

    void fw_destroy(fw_watcher *w) {
        if (w->stream) {
            FSEventStreamStop(w->stream);
            FSEventStreamInvalidate(w->stream);
            FSEventStreamRelease(w->stream);
        }
        if (w->queue) dispatch_release(w->queue);
        pthread_mutex_destroy(&w->mutex);
        free(w);
    }

#elif defined(_WIN32)
    #include <windows.h>

    struct fw_watcher {
        HANDLE handle;
        OVERLAPPED overlapped;
        char buffer[4096];
        char path[MAX_PATH];
        fw_event current;
        int pending;
    };

    fw_watcher* fw_create(void) {
        fw_watcher *w = calloc(1, sizeof(fw_watcher));
        w->overlapped.hEvent = CreateEvent(NULL, FALSE, FALSE, NULL);
        return w;
    }

    int fw_add(fw_watcher *w, const char *path, int recursive) {
        strncpy(w->path, path, MAX_PATH - 1);
        w->handle = CreateFile(path, FILE_LIST_DIRECTORY,
            FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
            NULL, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OVERLAPPED, NULL);
        
        if (w->handle == INVALID_HANDLE_VALUE) return -1;
        
        return ReadDirectoryChangesW(w->handle, w->buffer, sizeof(w->buffer), recursive,
            FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_DIR_NAME | 
            FILE_NOTIFY_CHANGE_LAST_WRITE, NULL, &w->overlapped, NULL) ? 0 : -1;
    }

    fw_event* fw_poll(fw_watcher *w, int timeout_ms) {
        DWORD result = WaitForSingleObject(w->overlapped.hEvent, timeout_ms);
        if (result != WAIT_OBJECT_0) return NULL;
        
        DWORD bytes;
        if (!GetOverlappedResult(w->handle, &w->overlapped, &bytes, FALSE)) return NULL;
        
        FILE_NOTIFY_INFORMATION *info = (FILE_NOTIFY_INFORMATION *)w->buffer;
        
        w->current.type = 0;
        if (info->Action == FILE_ACTION_MODIFIED) w->current.type = FW_MODIFIED;
        else if (info->Action == FILE_ACTION_ADDED) w->current.type = FW_CREATED;
        else if (info->Action == FILE_ACTION_REMOVED) w->current.type = FW_DELETED;
        else if (info->Action == FILE_ACTION_RENAMED_OLD_NAME || 
                 info->Action == FILE_ACTION_RENAMED_NEW_NAME) w->current.type = FW_RENAMED;
        
        if (w->current.type) {
            WideCharToMultiByte(CP_UTF8, 0, info->FileName, info->FileNameLength / 2, 
                               w->current.path, sizeof(w->current.path), NULL, NULL);
            w->current.path[info->FileNameLength / 2] = 0;
        }
        
        ReadDirectoryChangesW(w->handle, w->buffer, sizeof(w->buffer), TRUE,
            FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_DIR_NAME | 
            FILE_NOTIFY_CHANGE_LAST_WRITE, NULL, &w->overlapped, NULL);
        
        return w->current.type ? &w->current : NULL;
    }

    void fw_destroy(fw_watcher *w) {
        CloseHandle(w->handle);
        CloseHandle(w->overlapped.hEvent);
        free(w);
    }
#endif

int main() {
	  fw_watcher *w = fw_create();
    fw_add(w, ".", 1);

    while (1) {
        fw_event *e = fw_poll(w, 1000);
        if (e) printf("%s: %d\n", e->path, e->type);
    }

    fw_destroy(w);
}
