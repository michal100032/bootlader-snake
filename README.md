# Bootlader Snake
Very basic implementation of the classic game Snake written in x86 assembly that fits into the 512 byte long boot sector.

![Screenshot from 2024-04-28 10-46-38](https://github.com/michal100032/bootloader-snake/assets/53525961/6489ce37-8299-4005-ae82-4e65f2a06fe7)

## Build and run
To run the game first clone the repository:
```
git clone git@github.com:michal100032/bootloader-snake.git
cd bootloader-snake
```
And then to run the project with `qemu`:
```
make run
```
## Inspiration
The project was heavily inspired by [zenoamaro's bootloader pong](https://github.com/zenoamaro/bootloader-pong).
