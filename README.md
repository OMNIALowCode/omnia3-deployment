# OMNIA 3 Deployment

Repository with samples for the OMNIA Platform version 3 deployment operations.

## Install Omnia Platform 

Script `omnia-install.sh` can be used to install Omnia Platform along with all its software requirements on a new infrastructure.
 
### Usage

1. Copy [omnia-install.sh](https://github.com/OMNIALowCode/omnia3-deployment/master/omnia-install.sh)  file to the Ubuntu machine where OMNIA Platform will be installed
2. If necessary, grant access privileges to execute the bash script

```
    chmod +x omnia-install.sh
```

3. Execute the script

```
    sudo ./omnia-install.sh
```

## Update Omnia Platform version

Script `omnia-update.sh` can be used to update Omnia Platform to the latest version available on the Platform Feed.

### Usage

1. Copy [omnia-update.sh](https://github.com/OMNIALowCode/omnia3-deployment/master/omnia-update.sh) file to the Ubuntu machine where OMNIA Platform will be installed
2. If necessary, grant access privileges to execute the bash script

```
    chmod +x omnia-update.sh
```

3. Execute the script

```
    sudo ./omnia-update.sh
```

## License

OMNIA 3 Deployment scripts are available under the [MIT license](http://opensource.org/licenses/MIT).