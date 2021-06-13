
## How to create a SystemImage with GLMakie.jl to reduce the startup time

First make sure the KiteViewer directory is the current directory. Then execute the following commands:

```bash
./create_sys_image.sh
```

Finally, use the following command to launch to launch the GUI:
```./kiteviewer.sh```
or, if you just want to launch Julia:
```./run_julia.sh```


On my computer (i7-7700K) this reduced the startup time for the application from 69s to 11s.

## Packages that are included
The following packages are compiled into the Julia system image:
GLMakie, Arrow, MeshIO, RecursiveArrayTools, Revise, Rotations, StaticArrays, StructArrays, YAML

If you are using other packages a lot you can add them to the system image by editing the
file "test/create_sys_image.jl" and then executing ```./create_sys_image.sh```.

## Troubleshooting

### Error "Cannot find crti.o" on Linux
Install the package gcc-multilib
```
sudo apt install gcc-multilib
``` 
