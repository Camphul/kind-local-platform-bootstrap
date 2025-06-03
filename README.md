# Kind Local Platform Bootstrap

Kind cluster bootstrapping utility for providing a local Kubernetes dev platform for developers.
This aims to decrease the differences between a dedicated Kubernetes cluster/platform and vanilla Kind,
There were too many things that made the default Kind setup unusable for me.

## Requirements

Ensure these are installed on your machine:

- kind
- helmfile
- kubectl
- docker
- make

## Usage

Thwse are some commands:

```shell
make cluster-create  # Create a new Kind cluster using kind-config.yaml
make cluster-destroy # Destroy the Kind cluster                      
make helmfile-apply  # Apply helmfile to the Kind cluster          
make up              #- Create cluster and apply helmfile                       
make down            # Destroy and cleanup                                 
```

Run `make` to print the help menu.

## Installed services on Kind

Still WIP but now:

- `ingress-nginx` that uses hostPort 80/443 TCP so you can access it through `localhost:80` / `localhost:443`
- more stuff to come

## License

This project is licensed under the terms of the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html).  
See the [LICENSE](LICENSE) file for details.
