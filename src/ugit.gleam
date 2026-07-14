import argv
import gleam/crypto
import gleam/io
import gleam/result
import gleam/string
import simplifile

// pub type GitRep {
//   GitRep
// }

pub fn main() -> Nil {
  io.println("Hello from ugit!")
  case argv.load().arguments {
    ["init"] -> git_init(".")
    ["init", path] -> git_init(path)
    _ -> io.println("usage: ugit init [path]")
  }
}

pub fn git_init(worktree: String) -> Nil {
  let gitdir = string.join([worktree, ".git"], "/")
  case simplifile.is_directory(gitdir) {
    Ok(True) -> io.println("respository already exists: " <> gitdir)
    Ok(False) -> {
      case creat_respository(gitdir) {
        Ok(Nil) -> io.println("initialized empty ugit")
        Error(err) -> io.println("error: " <> simplifile.describe_error(err))
      }
    }
    Error(file_error) ->
      io.println("error:" <> simplifile.describe_error(file_error))
  }
}

// 创建仓库
fn creat_respository(gitdir: String) -> Result(Nil, simplifile.FileError) {
  // 创建所有的文件夹
  use _ <- result.try(simplifile.create_directory_all(gitdir))
  use _ <- result.try(simplifile.create_directory_all(join(gitdir, "objects")))
  use _ <- result.try(simplifile.create_directory_all(join(gitdir, "refs")))
  use _ <- result.try(
    simplifile.create_directory_all(join(gitdir, "refs/HEAD")),
  )
  use _ <- result.try(simplifile.write(
    to: join(gitdir, "description"),
    contents: "Unname respository; edit this file name the repository.\n",
  ))
  simplifile.write(
    to: join(gitdir, "config"),
    contents: "[core]\n\trepositoryformatversion = 0\n\tfilemode =
      false\n\tbare = false\n",
  )
}

fn join(left: String, right: String) -> String {
  string.join([left, right], "/")
}
