TZBoot
======

An ARM TrustZone stub for iPhone 4 (incomplete. doesn't load any boot image yet, however it drops into
non-secure mode and sets up SMC/MON32-mode handlers for that instruction. You need to implement your own
image bootstrap.)

See source file for compilation notes. Boot this as an iBEC or something.
