import argv
import gleam/io
import gleam/result
import gleam/string
import simplifile

pub fn main() -> Nil {
  case argv.load().arguments {
    ["init"] -> git_init(".")
    ["init", path] -> git_init(path)
    _ -> io.println("usage: ugit init [path]")
  }
}

pub fn git_init(worktree: String) -> Nil {
  let gitdir = join(worktree, ".git")

  case simplifile.is_directory(gitdir) {
    Ok(True) -> io.println("repository already exists: " <> gitdir)
    Ok(False) -> {
      case create_repository(gitdir) {
        Ok(Nil) -> io.println("initialized empty ugit")
        Error(err) -> io.println("error: " <> simplifile.describe_error(err))
      }
    }
    Error(file_error) ->
      io.println("error: " <> simplifile.describe_error(file_error))
  }
}

fn create_repository(gitdir: String) -> Result(Nil, simplifile.FileError) {
  use _ <- result.try(simplifile.create_directory_all(gitdir))
  use _ <- result.try(simplifile.create_directory_all(join(gitdir, "branches")))
  use _ <- result.try(simplifile.create_directory_all(join(gitdir, "objects")))
  use _ <- result.try(simplifile.create_directory_all(join(gitdir, "refs")))
  use _ <- result.try(
    simplifile.create_directory_all(join(gitdir, "refs/heads")),
  )
  use _ <- result.try(
    simplifile.create_directory_all(join(gitdir, "refs/tags")),
  )
  use _ <- result.try(simplifile.write(
    to: join(gitdir, "HEAD"),
    contents: "ref: refs/heads/master\n",
  ))
  use _ <- result.try(simplifile.write(
    to: join(gitdir, "description"),
    contents: "Unnamed repository; edit this file to name the repository.\n",
  ))
  simplifile.write(
    to: join(gitdir, "config"),
    contents: "[core]\n\trepositoryformatversion = 0\n\tfilemode = false\n\tbare = false\n",
  )
}

fn join(left: String, right: String) -> String {
  string.join([left, right], "/")
}
