# socket server
# Reference: https://github.com/Brian-ED/bqn-socket/blob/master/socket.bqn


SocketServer←{𝕊:
  af_inet      ← 2
  inaddr_any   ← 0
  sock_stream  ← 1
  sol_socket   ← 65535 # 0xffff
  so_reuseaddr ← 2 # 0x0004
  port         ← 8080

  sockaddr    ← "{u16,[14]u8}"
  sockaddr_in ← "{u16,u16,{u32},[8]u8}"

  socket     ← @ •FFI "i32"‿"socket"‿"i32"‿"i32"‿"i32"
  setsockopt ← @ •FFI "i32"‿"setsockopt"‿"i32"‿"i32"‿"i32"‿"*i32"‿"i32"
  bind       ← @ •FFI "i32"‿"bind"‿"i32"‿('&'∾sockaddr_in)‿"u32"
  listen     ← @ •FFI "i32"‿"listen"‿"i32"‿"i32"
  accept     ← @ •FFI "i32"‿"accept"‿"i32"‿('&'∾sockaddr)‿"&u32"

  htons      ← @ •FFI "i32"‿"htons"‿"i32"
  read       ← @ •FFI "i32"‿"read"‿"i32"‿"&u8"‿"i32"
  
  srv_addr ← ⟨af_inet,Htons ⟨port⟩,⟨0⟩,8⥊0⟩

  srv_fd←Socket af_inet‿sock_stream‿0
  Setsockopt srv_fd‿sol_socket‿so_reuseaddr‿⟨1⟩‿4
  Bind ⟨srv_fd,⋈srv_addr,16⟩
  Listen srv_fd‿3

  •Show "listening to port "∾•Fmt port
  {𝕊:
    c_fd‿·‿· ← Accept⟨srv_fd, ⋈⟨0, 14⥊0⟩, ⋈16⟩

    n‿buf←Read ⟨c_fd,1024⥊0,1024⟩
    •SHow •FromUTF8 n↑buf
    𝕩
  } •_while_ ⊢ 1
}

Stdin⇐{
  vmap‿cm‿file‿pos←𝕩
  "variable map should be a hashmap" ! 3=•Type vmap

}

# TODO input for tests


SocketServer @
