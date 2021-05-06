
## How to create a SystemImage with Makie.jl to reduce the startup time

First make sure the KiteViewer directory is the current directory. Then execute the following commands:

```bash
./create_sys_image.sh
```

Finally, use the following command to launch Julia:
```./kiteviewer.sh```
to launch the GUI without julia command line:


On my computer (i7-7700K) this reduced the startup time from 69s to 9s.

## Troubleshooting

### Error "Cannot find crti.o" on Linux
Install the package gcc-multilib
```
sudo apt install gcc-multilib
``` 
