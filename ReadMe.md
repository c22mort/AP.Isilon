# AP.Isilon
EMC Isilon Management Pack - A free alternative Isilon Management Pack for System Center Operations Manager.

## AP.Isilon.Discovery (Console Application)
* **Isilon Clusters**
* **Ision Node Hardware** - Network Interfaces, Temperature Sensors, Disks, Licences and Protocols.

This Application utilizes 2 csv files clusters.csv and config.csv.
**clusters.csv** this is a list of; cluster ip, SNMP Community, Isilon ISI username, Isilon ISI Password. 
There is a an example file called example_clusters.csv included, rename this file to clusters.csv and fill in your information, the header row is needed.
**config.csv** this currently just has the Management server that the discovery data will be sent to, if this file doesn't exist localhost will be used, useful if you are running it on a management server.  Again an example file is included.
I have this scheduled to run every 4 Hours, but as we are only discovering hardware you can run it less frequently if you so desire.
Monitoring and Performance is gathered every 5-15 minutes.

Also Containment relationships between are discovered by this app.

## AP.Isilon (SCOM 2016 Management Pack)
* **Additional SNMP Discovery of volatile data is handled by this SCOM Management Pack.
* **SNMP Unit Monitors (Cluster Health, Node Health, Disk Health, Temp. Sensor Temperature, Licence Health, Protocol Health, Network Interface Health)
* **SNMP Performance Collection (Cluster/Node/Protocol Network Inbound/Outbound Kb, Cluster Used Capacity (% and Tb), Snapshot Used Capacity (% and Tb), Protocol latency and More )

Download Installer from https://c22mort.github.io/
GitHub Repo : https://github.com/c22mort/AP.Isilon