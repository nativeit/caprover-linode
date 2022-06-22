# Deploy Caprover on Linode VPS

This is a Linode StackScript for deploying Caprover onto a Debian Linode VPS. Suggested minimum specs can be found in the [Caprover Documentation](https://caprover.com/docs/get-started.html#b2-server-specs). 

## Prerequisites

Before deploying your instance, you will need to be sure you have the following:

  - **Domain Name**
    - If you need to register a new domain name, I generally use [Gandi.net](https://www.gandi.net/en-US), but if you're setting up a VPS you probably know your way around this process already.
    - Caprover deploys each app as a subdomain of your primary domain, so for example if you deployed an instance of Gitea on your domain `example.tld`, and named the app `gitea` during setup, Caprover would deploy the app at `http://gitea.example.tld`.
    - In order to allow Caprover to obtain and install SSL certificates for your apps automatically, be sure to add **A/AAAA records** to your domain's DNS configuration with a wildcard subdomain, like this `* 3600 IN A 12.34.56.789` and `* 3600 IN AAAA 2002::1234:abcd:ffff:c0a8:101` for pointing `*.example.tld` to your Linode's IP addresses.
  - **Linode VPS**
    - **CPU**: 2+ cores is recommended. Caprover and most Docker images can be built and run on most common CPU architectures.
    - **Memory**: Caprover requires at least 1GB of RAM for installation, but 4GB or more is recommended for running multiple apps/containers.

## Features

Deploying a new Linode using this StackScript will take care of most everything you will need in terms of OS, service, and software configurations. 

The following are included in the StackScript based on recommendations from [Caprover's Documentation](https://caprover.com/docs/get-started.html).

  - **Clean OS Install**: Caprover requires exclusive access to ports 80 and 443 to deploy apps and obtain SSL certificates. Any other web servers such as Apache will conflict with Caprover's access to these ports. For this reason, it is **highly** recommended that you install Caprover on a fresh system (which of course this StackScript involves the provisioning of a fresh Linode VPS/configuration).
  - **Docker**: Caprover uses Docker for building and deploying apps and services. Docker CE should be installed using its official instructions. Snap installs have know issues, and should be avoided.
  - **Firewall**: Be sure the following ports are opened and accessible: `80/tcp, 443/tcp, 996/tcp, 2377/tcp, 3000/tcp, 4789/tcp, 7946/tcp, 2377/udp, 4789/udp, 7946/udp`. This StackScript automatically installs and configures UFW with the necessary ports as well as port 22 for SSH:
    ```
    ufw allow 22,80,443,3000,996,7946,4789,2377/tcp
    ufw allow 7946,4789,2377/udp
    ufw reload && ufw enable
    ```
    
### Further Reading

If you want to know more about Caprover, [visit their website](https://caprover.com).

### Acknowledgements

Caprover is an open-source PaaS (Platform-as-a-Service) app/database deployment and web server manager, similar to services like Heroku. It was created by [@githubsaturn](https://github.com/githubsaturn) with help from [contributors](https://github.com/caprover/caprover/graphs/contributors).

This StackScript was created and is maintained by [@nativeit](https://github.com/nativeit). Aside from contributing app templates to Caprover's [One Click Apps](https://github.com/caprover/one-click-apps) repository, I am not affiliated with Caprover or their developers in any way.
