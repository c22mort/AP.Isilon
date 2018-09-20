using Microsoft.EnterpriseManagement.Common;
using Microsoft.EnterpriseManagement.Configuration;
using Renci.SshNet;
using System;
using System.Collections.Generic;
using System.Web.Script.Serialization;

namespace AP.Isilon.Discovery.Classes
{
    class IsilonCluster
    {
        // Cluster SCOM Object
        public CreatableEnterpriseManagementObject SCOM_Object;

        // List of Nodes in this Cluster
        public List<IsilonNode> NodeList = new List<IsilonNode>();

        // SSH Client Instance
        SshClient client;


        /// <summary>
        /// Default Constructor
        /// </summary>
        /// <param name="address">IP Address : From CSV File</param>
        /// <param name="community">SNMP Community  : From CSV File</param>
        /// <param name="username">SNMP UserName : From CSV File</param>
        /// <param name="password">SNMP Password : From CSV File</param>
        public IsilonCluster(string address, string community, string username, string password)
        {
            // Get Variable that are used in more than one place)
            string clusterGUID = SNMP.GetSNMP(SNMP.clusterGUID, address, 161, community)[0].Data.ToString();
            string clusterName = SNMP.GetSNMP(SNMP.clusterName, address, 161, community)[0].Data.ToString();
            string configuredNodes = SNMP.GetSNMP(SNMP.configuredNodes, address, 161, community)[0].Data.ToString();
            int nodeCount = Convert.ToInt32(SNMP.GetSNMP(SNMP.nodeCount, address, 161, community)[0].Data.ToString());

            // Get and Calculate capacity
            Double capacity = Convert.ToDouble(SNMP.GetSNMP(SNMP.ifsTotalBytes, address, 161, community)[0].Data.ToString());
            capacity = Math.Round((capacity / 1024 / 1024 / 1024 / 1024), 2);

            // Get and Calculate Used Capacity
            Double used = Convert.ToDouble(SNMP.GetSNMP(SNMP.ifsUsedBytes, address, 161, community)[0].Data.ToString());
            used = Math.Round((used / 1024 / 1024 / 1024 / 1024), 2);

            // Get and Calculate Available Capacity
            Double available = Convert.ToDouble(SNMP.GetSNMP(SNMP.ifsAvailableBytes, address, 161, community)[0].Data.ToString());
            available = Math.Round((available / 1024 / 1024 / 1024 / 1024), 2);

            // Calculate Percentage Used
            Double percentageUsed = Math.Round(((used / capacity) * 100), 2);

            // Create Root Entity Class & Display Name Prop
            ManagementPackClass mpc_Entity = SCOM.GetManagementPackClass("System.Entity");
            ManagementPackProperty mpp_EntityDisplayName = mpc_Entity.PropertyCollection["DisplayName"];

            // Create Cluster Management Pack Class
            ManagementPackClass mpc_Cluster = SCOM.GetManagementPackClass("AP.Isilon.Cluster");

            // Create New Cluster Object
            SCOM_Object = new CreatableEnterpriseManagementObject(SCOM.m_managementGroup, mpc_Cluster);

            // Display Name of Root Entity (KEY Property)
            SCOM_Object[mpp_EntityDisplayName].Value = clusterName;

            // Set Properties of Cluster
            //Starting with name (Key Property of Cluster)
            ManagementPackProperty mpp_ClusterName = mpc_Cluster.PropertyCollection["Name"];
            SCOM_Object[mpp_ClusterName].Value = clusterName;
            // GUID Property
            ManagementPackProperty mpp_ClusterGUID = mpc_Cluster.PropertyCollection["GUID"];
            SCOM_Object[mpp_ClusterGUID].Value = clusterGUID;
            // IPAddress 
            ManagementPackProperty mpp_ClusterIP = mpc_Cluster.PropertyCollection["IPAddress"];
            SCOM_Object[mpp_ClusterIP].Value = address;
            // SNMP Community String
            ManagementPackProperty mpp_ClusterCommunity = mpc_Cluster.PropertyCollection["Community"];
            SCOM_Object[mpp_ClusterCommunity].Value = community;
            // NodeCount
            ManagementPackProperty mpp_ClusterNodeCount = mpc_Cluster.PropertyCollection["NodeCount"];
            SCOM_Object[mpp_ClusterNodeCount].Value = nodeCount;
            // Configured Nodes
            ManagementPackProperty mpp_ClusterConfiguredNodes = mpc_Cluster.PropertyCollection["ConfiguredNodes"];
            SCOM_Object[mpp_ClusterConfiguredNodes].Value = configuredNodes;
            // Online Nodes
            ManagementPackProperty mpp_ClusterOnlineNodes = mpc_Cluster.PropertyCollection["OnlineNodes"];
            SCOM_Object[mpp_ClusterOnlineNodes].Value = SNMP.GetSNMP(SNMP.onlineNodes, address, 161, community)[0].Data.ToString();
            // Offline Nodes
            ManagementPackProperty mpp_ClusterOfflineNodes = mpc_Cluster.PropertyCollection["OfflineNodes"];
            SCOM_Object[mpp_ClusterOfflineNodes].Value = SNMP.GetSNMP(SNMP.offlineNodes, address, 161, community)[0].Data.ToString();
            // Location
            ManagementPackProperty mpp_ClusterLocation = mpc_Cluster.PropertyCollection["Location"];
            SCOM_Object[mpp_ClusterLocation].Value = SNMP.GetSNMP(SNMP.sysLocation, address, 161, community)[0].Data.ToString();
            // Contact
            ManagementPackProperty mpp_ClusterContact = mpc_Cluster.PropertyCollection["Contact"];
            SCOM_Object[mpp_ClusterContact].Value = SNMP.GetSNMP(SNMP.sysContact, address, 161, community)[0].Data.ToString();
            // Capacity
            ManagementPackProperty mpp_ClusterCapacity = mpc_Cluster.PropertyCollection["Capacity"];
            SCOM_Object[mpp_ClusterCapacity].Value = capacity;
            // Used Capacity
            ManagementPackProperty mpp_ClusterUsedCapacity = mpc_Cluster.PropertyCollection["Used"];
            SCOM_Object[mpp_ClusterUsedCapacity].Value = used;
            // Available Capacity
            ManagementPackProperty mpp_ClusterAvailableCapacity = mpc_Cluster.PropertyCollection["Available"];
            SCOM_Object[mpp_ClusterAvailableCapacity].Value = available;
            // Used Percentage
            ManagementPackProperty mpp_ClusterUsedPercentage = mpc_Cluster.PropertyCollection["UsedPercentage"];
            SCOM_Object[mpp_ClusterUsedPercentage].Value = percentageUsed;

            // Get Nodes
            try
            {
                // Create SSH Connection to Cluster
                client = new SshClient(address, username, password);
                client.Connect();

                // Loop Though All Nodes
                for (int i = 1; i <= nodeCount; i++)
                {
                    // Get Interfaces for this Node
                    var cmd = client.CreateCommand("isi network interfaces list -v -z -a -n " + i + " --format json");
                    cmd.Execute();
                    // Collect Result (Will be In JSON Format
                    string result = cmd.Result;


                    JavaScriptSerializer js = new JavaScriptSerializer();
                    IsilonNetworkInterface[] interfaces = js.Deserialize<IsilonNetworkInterface[]>(result);

                    // Create New Node
                    IsilonNode newNode = new IsilonNode(clusterName, i, interfaces, address, community);

                    // Add Node to NodeList
                    NodeList.Add(newNode);
                }


                // Dispose of Cluster SSH Connection
                client.Disconnect();
                client.Dispose();
            }
            catch (Exception ex)
            {
                if (client.IsConnected)
                {
                    client.Disconnect();
                    client.Dispose();
                }
                Program.log.Error(clusterName + " : " + ex.Message);
            }

        }
    }
}
