This fork is an attempt to get NV to run on my M2 Macbook Pro.

2024-11-28:
Got it running by changing the deployment target to 14.6 (Sonoma) and
changing some compliler flags:

Added: -Wno-error=incompatible-function-pointer-types
Removed: -whatsloaded
Removed: -L/usr/local/opt/openssl/lib
