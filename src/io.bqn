# socket server
# Reference: https://github.com/Brian-ED/bqn-socket/blob/master/socket.bqn


SocketServer←{𝕊:
  af_inet←2
  inaddr_any←0
  sock_stream←1
  sol_socket←65535 # 0xffff
  so_reuseaddr←2 # 0x0004
  address_len ← 16
  port←8080

  sockaddr_in ⇐ "{u16,u16,{u32},[8]u8}"

  socket     ← @ •FFI "i32"‿"socket"‿"i32"‿"i32"‿"i32"
  setsockopt ← @ •FFI "i32"‿"setsockopt"‿"i32"‿"i32"‿"i32"‿"*i32"‿"i32"
  bind       ← @ •FFI "i32"‿"bind"‿"i32"‿('&'∾sockaddr_in)‿"u32"
  listen     ← @ •FFI "i32"‿"listen"‿"i32"‿"i32"
  htons      ← @ •FFI "i32"‿"htons"‿"i32"

 
  address ← ⟨af_inet,Htons ⟨port⟩,⟨0⟩,8⥊0⟩

  server_fd←Socket af_inet‿sock_stream‿0
  Setsockopt server_fd‿sol_socket‿so_reuseaddr‿⟨1⟩‿4
  Bind ⟨server_fd,⋈address,16⟩
  Listen server_fd‿3

  •Show "listening to port "∾•Fmt port
  
}

# stdin
STDIN⇐{
  vmap‿cm‿file‿pos←𝕩
  "variable map should be a hashmap" ! 3=•Type vmap

}


SocketServer @
