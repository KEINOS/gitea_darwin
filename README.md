# Easy Gitea installer for Mac

## What is Gitea?

Gitea is a simple and single application that allows you to self-host a git server.

- See more about: [https://gitea.io/](https://gitea.io/)

## Install and update

To install [Gitea](https://gitea.io/) on your Mac, just run this command below under preferred directory to install. This command will update the binary if Gitea is already installed.

```bash
bash <(curl -s https://keinos.github.io/gitea_darwin/install.sh)
```

- **NOTE:** This installer only works on and is for Mac.
- [See the source of the installer](https://github.com/KEINOS/gitea_darwin/blob/master/install.sh)

## Tested environment

- macOS HighSierra (OSX 10.13.6)
    - MacBook Pro (Retina, 13-inch, Early 2015)
    - 2.7 GHz Intel Core i5

- For other confirmed environments see [issue #1](https://github.com/KEINOS/gitea_darwin/issues/1)


## What this script does?

It eases your usual process to install Gitea such as below:

1. It downloads the archived Gitea binary file and the checksums for Mac(darwin, arm64) from the [latest releases pages](https://github.com/go-gitea/gitea/releases).
2. Compares the checksum of the archive.
3. Extracts the archive.
4. Changes mode as executable.
5. Checks and displays the binary version.
6. Search un-used ports for buil-in ssh and web server of Gitea.
7. Sets the SSH and HTTP ports found as default.
8. Runs the Gitea and launches the default browser to setup.

## License

MIT License. Same as Gitea, it is.
