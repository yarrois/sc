# SC

## Short description

This project deploys a loadbalancer, two webservers and a SQL database on a local hypervisor running CentOS 8, KVM and OpenvSwitch. A very simple REST API is implemented that returns all the contents of a table of the SQL database.


## Requirements

This project has been tested under the following conditions and requirements:
* CentOS 8
* Internet connection to reach the CentOS repositories
* GitHub self-hosted runner must be setup
* Routing is enabled on the hypervisor
* ‘automation’ user with passwordless root privileges and SSH key
* ansible installed


## Installation

If you don't setup the GitHub self-hosted runner to your own machine, then follow the procedure here. First clone the project to your local machine. By default the target for the hypervisor will be the localhost the Ansible playbook is running from.

Make sure the authorized_keys file with your own public key in:
files/authorized_keys

Replace the default passwords by your customized passwords in vault-pw and vault.yaml.

The following playbook set ups the hypervisor, deploys the VMs and configures the services. 
$ ansible-playbook --vault-password-file vault-pw site.yaml

The individual playbooks are also able to run independently so it is easy to focus on for example the configuration of a specific service.
$ ansible-playbook --vault-password-file vault-pw hypervisor.yaml
$ ansible-playbook --vault-password-file vault-pw vms.yaml
$ ansible-playbook --vault-password-file vault-pw loadbalancer.yaml
$ ansible-playbook --vault-password-file vault-pw webserver.yaml
$ ansible-playbook --vault-password-file vault-pw database.yaml


## Usage

Once deployed you can test the REST API by curling or visiting the following link with a browser http://ucpe.swisscom.com/api.php
You can replace files/users.sql by your own dump of your SQL database to get it imported.


## Full description

### Hypervisor

I only have one available machine with limited resources and since this is a small project I am just using Libvirt and KVM. One could make use of for example ovirt if you have more machines and resources available or you could even make use of an OpenStack cloud and create your networks and spin up VMs through those APIs.


### Networking

OpenvSwitch is used to deploy the networking for the VMs. Note that I created ifcfg files for the hypervisor ports, but create the bridges through OpenvSwitch directly. Creating the bridges through OpenvSwitch ensures that when restarting the network the bridges does not get removed and recreated by OpenvSwitch. This is important because if the bridge gets removed from OpenvSwitch it will also disconnect all ports connected to that bridge and the VM network connectivity will be gone after the hypervisor network restart.

               ------------
              |Loadbalancer|
               ------------
                |   |
    --*-------------*---------------------------- red
      |         |
      |         |  ------------     ------------ 
      |         | | Webserver1 |   | Webserver2 |
      |         |  ------------     ------------ 
      |         |   |   |            |   |
    ----*---------------*----------------*------- orange
      | |       |   |                |
      | |       |   |  ------------  |
      | |       |   | |  Database  | |
      | |       |   |  ------------  |
      | |       |   |   |   |        |
    ------*-----------------*-------------------- green
      | | |     |   |   |            |
    --------*---*---*---*------------*----------- mgmt
      | | | |
     ------------
    | Hypervisor |
     ------------

Four bridges are created that simulate four different networks/zones to isolate traffic for more security, e.g. the database cannot queried directly from the outside world:

* mgmt: used for configuring the VMs
* red: this is where the requests from the clients come in
* orange: loadbalancer sends request to one of the webservers
* green: webservers communicate with database 

In this setup the VMs get internet access via the mgmt network routed through the hypervisor. In a real world scenario, the internet access could be replaced by an internal repository that is accessible through the management network.

In this setup the hypervisor will route everything between the different zones. It would be best to set up firewall rules between the different zones so you can exactly control your traffic flows. For simplicity in this project I left this out.


### Firewall Hypervisor

Firewall is enabled. All OpenvSwitch hypervisor ports are connected to the internal zone. The internet connection port is connected to the default public. Masquerading is enabled on public so VMs can reach the internet.


### VMs

The VMs are created using Libvirt. A qcow2 is downloaded and a basic configuration is added before spinning up the different VMs. In a cloud environment it would make more sense to use cloud-init to setup the automation user, networking, etc., but in this case I decided to virt-customize the qcow2 directly so I don’t have to deal with attaching a custom cloud init ISO image.


### Loadbalancer

HAproxy is used as loadbalancer.


### Webservers

Httpd and PHP are installed. A very simple api.php page is created that returns all data in JSON format from the users table of the sqltest database.


### Databases

MariaDB is installed and the database is populated with the data in files/users.sql. Users are created that has all permit access to the specific sqltest database so that only the webservers can log into the database.


### General

Selinux and firewalld are enabled on all components.

VMs are updated with security patches.


### GitHub workflows

The workflow is targetting my own machine so from security perspective it is not very safe to keep this repo public, because in theory someone could push and start the workflow. Limiting the access or limiting the triggers for the workflow can help with unwanted deployment. For simplicity I just opened everything to show the workflow and keep my actions-runner offline on my machine.

