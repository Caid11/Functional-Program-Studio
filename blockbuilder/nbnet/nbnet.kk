// extern import
//   c { file = "nbnet.h" }

extern import
  c file "nbnet-inline.c"

alias nbnet-io = io

//================================================================================
// NBNet types

alias connectionHandle = int
alias ptr = int64

struct messageInfo
  ty : int
  channel-id : int
  data : ptr
  sender : connectionHandle

val maxMessageTypes : int = 255
val byteArrayMessageType : int = maxMessageTypes - 4

//================================================================================
// NBNet functions

extern gameServer-sendReliableByteArrayTo(connection-handle: connectionHandle, bytes : vector<char>) : nbnet-io int
  c "kk_nbnet_gameServer_sendReliableByteArrayTo"

extern gameServer-getMessageInfo() : nbnet-io messageInfo
  c "kk_nbnet_GameServer_GetMessageInfo"

//================================================================================
// Functions to convert NBNet messages to Koka types

extern nbnet-message-to-byte-vector(ptr : int64) : nbnet-io vector<char>
  c "kk_nbnet_message_to_byte_vector"
