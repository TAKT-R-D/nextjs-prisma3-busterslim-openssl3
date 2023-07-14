# nextjs-prisma3-busterslim-openssl3

OpenSSL 1.1.1 support will expire on Sep.11, 2023.
Upgrading OpenSSL version is highly recommended for your app security.
However, to keep using alpine requires Prisma 4.10.0+ and to examin Prisma upgrade will take time.
This dockerfile is for prisma older version users.

Plan to upgrade Prisma as well.

## Requirements

- Prisma: less than 4.10.0
- Platform: both x86_64 / ARM64

If your prisma version is 4.10.0 or later, using alpine is better.
Latest prisma version is 5.0.0

## versions

- Debian: 10 (Current LTS)
- OpenSSL: 3.0.8 (FIPS validated)
- node: 18.16.1
- yarn: 1.22.19

customize versions as your requirements.


## binaryTargets in schema.prisma

```
generator client {
  provider      = "prisma-client-js",
  binaryTargets = ["native", "debian-openssl-3.0.x", "linux-arm64-openssl-3.0.x"]
}
...
```

## Usage

```bash
$ docker build ./ -t {your_container_name}
```

or

```bash
$ docker build --platform linux/amd64 ./ -t {your_container_name}
```

## Note
When openssl3 is available with apt-get install, replace installing openssl from source parts.

Be patient to build linux/amd64 image on ARM64 platform, such as M1/M2 Mac.
"make isntall" takes soooooo long time to complete, feel like never ends...
On my M2 Macbook Pro, it took 2867.8sec for the first time. :(
