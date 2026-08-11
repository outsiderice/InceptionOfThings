# Inception-of-Things
This project is an introduction to using kubernetes.

## Pre-work
What is k8s?
An open source system for automating deployment, scaling, and management of containerized applications.

What is k3s?
Lightweight k8s distribution for IoT & Edge computing.

What is vagrant?
Command line utility for managing the lifecycle of virtual machines.

What is k3d?
A lightweight wrapper to run k3s in docker.

What is Argo CD?
A declarative, GitOps continuous delivery tool for Kubernetes.

### Setting up the environment
We decided to use cloud-init to be able to easily deploy our host machine with our preferred configuration, and specially as a more lightweight than other vm providers.

### Monitoring and testing
How do these technologies fail? What should I watch and how?
The 3 parts to this project are:
- K3s and Vagrant
- K3s and three simple applications
- K3d and Argo CD

## Part one
Set up 2 virtual machines with vagrant and install k3s in them.

### Requirements
- [ ] Specific machine names.
- [ ] Dedicated IP on the primary network interface.
- [ ] Be able to connect with SSH on both machines with no password.
- [ ] k3s installed in controller mode in machine one.
- [ ] k3s installed in agent mode in machine two.

### How to write a Vagrantfile according to modern practices

### Kubectl installation
kubectl is a command line tool for communicating with Kubernetes.

