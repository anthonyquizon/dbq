# Reference: https://github.com/Brian-ED/bqn-socket/blob/master/socket.bqn
# Reference: https://github.com/anthonyquizon/dbq/blob/bcd6c4bcff9c9912032a1c30b946bdba7158e47e/src/rt.bqn

⟨asc,uni⟩←•Import "cs.bqn"
⟨In,Out,term⟩←•args
OutR←term.OutRaw

e←@+27 ⋄ lf←@+10 ⋄ clear←e∾"[2K"∾e∾"[0G"

af_inet      ← 2
inaddr_any   ← 0
sock_stream  ← 1
sol_socket   ← 65535                                                  # 0xffff
so_reuseaddr ← 2                                                      # 0x0004
port         ← 𝕩
Op           ← 𝔽

sockaddr    ← "{u16,[14]u8}"
sockaddr_in ← "{u16,u16,{u32},[8]u8}"

socket     ← @ •FFI "i32"‿"socket"‿"i32"‿"i32"‿"i32"
setsockopt ← @ •FFI "i32"‿"setsockopt"‿"i32"‿"i32"‿"i32"‿"*i32"‿"i32"
bind       ← @ •FFI "i32"‿"bind"‿"i32"‿('&'∾sockaddr_in)‿"u32"
listen     ← @ •FFI "i32"‿"listen"‿"i32"‿"i32"
accept     ← @ •FFI "i32"‿"accept"‿"i32"‿('&'∾sockaddr)‿"&u32"
send       ← @ •FFI "i64"‿"send"‿"i32"‿"*u8"‿"u64"‿"i32"

htons      ← @ •FFI "i32"‿"htons"‿"i32"
read       ← @ •FFI "i32"‿"read"‿"i32"‿"&u8"‿"i32"
  
_SocketServer⇐{
  srv_addr ← ⟨af_inet,Htons ⟨port⟩,⟨0⟩,8⥊0⟩
  srv_fd←Socket af_inet‿sock_stream‿0
  Setsockopt srv_fd‿sol_socket‿so_reuseaddr‿⟨1⟩‿4
  Bind ⟨srv_fd,⋈srv_addr,16⟩
  Listen srv_fd‿3

  Out "listening to port "∾•Fmt port
  {𝕊:
    c_fd‿·‿· ← Accept⟨srv_fd, ⋈⟨0, 14⥊0⟩, ⋈16⟩
    n‿buf←Read ⟨c_fd,1024⥊0,1024⟩
    Op •FromUTF8 n↑buf
  } •_while_ ⊢ 1
}
