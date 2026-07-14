import gleam/bit_array
import gleam/crypto
import gleam/int
import gleam/string
import gzlib

pub type GitObject {
  Blob(BitArray)
}

pub type ObjectError {
  ShaError
  ZlibError
}

pub fn encode(obj: GitObject) -> BitArray {
  case obj {
    Blob(body) -> loose_object("blob", body)
  }
}

pub fn object_type(obj: GitObject) -> String {
  case obj {
    Blob(_) -> "blob"
  }
}

// 拼接oject格式
fn loose_object(kind: String, body: BitArray) {
  let header =
    bit_array.concat([
      bit_array.from_string(kind),
      bit_array.from_string(" "),
      bit_array.from_string(int.to_string(bit_array.byte_size(body))),
      <<0>>,
    ])
  bit_array.concat([header, body])
}

// 加密 二进制数据
pub fn sha1_hex(data: BitArray) {
  crypto.hash(crypto.Sha1, data)
}

// 压缩
pub fn zlib_compress(data: BitArray) {
  case gzlib.compress(data) {
    Error(Nil) -> Error(ZlibError)
    Ok(zlib_data) -> Ok(zlib_data)
  }
}

pub fn write_obj(gitdir: String, obj: GitObject) {
  let raw = encode(obj)
  let oid = sha1_hex(raw)
  let compressed = zlib_compress(raw)
  // let path = objec
  // zlib_compress
}

pub fn obj_path(gitdir: String, oid) {
  bit_array.slice(oid, 0, 2)
  //   int.to_base16()
  //   string.slice()
}
