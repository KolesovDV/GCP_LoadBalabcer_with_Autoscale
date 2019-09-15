NOTES
=======


## Some information about task perfomance

Google Cloud Platform (GCP) offers load balancing and autoscaling for groups of instances
Instance Groups
An instance group is a collection of VM instances that you can manage as a single entity.
Compute Engine offers two kinds of VM instance groups:
•	Managed instance groups (MIGs) allow you to operate applications on multiple identical VMs. You can make your workloads scalable and highly available by taking advantage of automated MIG services, including: autoscaling, autohealing, regional (multi-zone) deployment, and auto-updating.
•	Unmanaged instance groups allow you to load balance across a fleet of VMs that you manage yourself.
•	Managed instance groups (MIGs) are suitable for stateless serving workloads (such as a website frontend) and for batch, high-performance, or high-throughput compute workloads (such as image processing from a queue).
•	Each VM instance in a MIG is created from an instance template.
Unmanaged instance groups
Unmanaged instance groups can contain heterogeneous instances that you can arbitrarily add and remove from the group. Unmanaged instance groups do not offer autoscaling, auto-healing, rolling update support, or the use of instance templates and are not a good fit for deploying highly available and scalable workloads. Use unmanaged instance groups if you need to apply load balancing to groups of heterogeneous instances or if you need to manage the instances yourself.
According to the task “OPS: Ansible 13 Production ready” we are to manage instances using ansible. That’s why we chose “Unmanaged instance groups”. 
Unlike managed instance groups, unmanaged instance groups are just collections of unique instances that do not share a common instance template. Unmanaged groups do not create, delete, or scale the number of instances in the group.  You simply create a group, and add individual instances to the group later.


## Simple Steps:

- 1)	 Create Instance
- 2)	 Create unmanaged instance group
- 3)	 Create Load Balancer	
- 3.1) 	 Create health check( http or/and https)	
- 3.2) 	 Create global address	
- 3.3) 	 Create backend service using unmanaged group, health check	
- 3.4) 	 Create host and path rule(use backend, url_map, specify path)	
- 3.5) 	 Create ssl sertificate if  nessesary	
- 3.6) 	 Create frontend configuration(using global address create target to proxy and global forwarding rules)	
