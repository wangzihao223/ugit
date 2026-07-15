import gleam/bit_array
import gleam/crypto
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gzlib
import simplifile

pub type GitObject {
  Blob(BitArray)
}

pub type ObjectId {
  ObjectId(BitArray)
}

pub type ObjectError {
  FileError(simplifile.FileError)
  ZlibError
  InvalidObjectIdSize(Int)
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
fn loose_object(kind: String, body: BitArray) -> BitArray {
  let header =
    bit_array.concat([
      bit_array.from_string(kind),
      bit_array.from_string(" "),
      bit_array.from_string(int.to_string(bit_array.byte_size(body))),
      <<0>>,
    ])
  bit_array.concat([header, body])
}

// 计算 Git object id。这里返回的是 20 字节 raw SHA-1，不是 hex 字符串。
pub fn hash_object(data: BitArray) -> ObjectId {
  ObjectId(crypto.hash(crypto.Sha1, data))
}

pub fn object_id_to_hex(oid: ObjectId) -> String {
  let ObjectId(bytes) = oid
  bit_to_hex(bytes)
}

// 压缩
pub fn zlib_compress(data: BitArray) -> Result(BitArray, ObjectError) {
  case gzlib.compress(data) {
    Error(Nil) -> Error(ZlibError)
    Ok(zlib_data) -> Ok(zlib_data)
  }
}

pub fn write_obj(
  gitdir: String,
  obj: GitObject,
) -> Result(String, ObjectError) {
  let raw = encode(obj)
  let oid = hash_object(raw)

  use compressed <- result.try(zlib_compress(raw))
  use dir <- result.try(obj_dir(gitdir, oid))
  use path <- result.try(obj_path(gitdir, oid))

  use _ <- result.try(
    simplifile.create_directory_all(dir)
    |> result.map_error(FileError),
  )

  use _ <- result.try(
    simplifile.write_bits(to: path, bits: compressed)
    |> result.map_error(FileError),
  )
  Ok(object_id_to_hex(oid))
}

pub fn obj_dir(gitdir: String, oid: ObjectId) -> Result(String, ObjectError) {
  let ObjectId(bytes) = oid

  case bit_array.byte_size(bytes) {
    20 -> {
      let assert Ok(dir) = bit_array.slice(bytes, 0, 1)
      Ok(string.join([gitdir, "objects", bit_to_hex(dir)], "/"))
    }
    size -> Error(InvalidObjectIdSize(size))
  }
}

pub fn obj_path(gitdir: String, oid: ObjectId) -> Result(String, ObjectError) {
  let ObjectId(bytes) = oid

  case bit_array.byte_size(bytes) {
    20 -> {
      let assert Ok(dir) = bit_array.slice(bytes, 0, 1)
      let assert Ok(file) = bit_array.slice(bytes, 1, 19)

      Ok(string.join(
        [
          gitdir,
          "objects",
          bit_to_hex(dir),
          bit_to_hex(file),
        ],
        "/",
      ))
    }
    size -> Error(InvalidObjectIdSize(size))
  }
}

fn bit_to_hex(bin: BitArray) -> String {
  do_bit_to_hex(bin, [])
}

fn do_bit_to_hex(bin: BitArray, acc) {
  case bin {
    <<a, rest:bits>> -> {
      do_bit_to_hex(rest, [byte_to_hex(a), ..acc])
    }
    <<>> -> {
      list.reverse(acc)
      |> string.concat()
    }
    _ -> panic as "expected byte-aligned bit array"
  }
}

fn byte_to_hex(byte: Int) -> String {
  let hex = int.to_base16(byte)
  case string.length(hex) {
    1 -> "0" <> hex
    _ -> hex
  }
}
