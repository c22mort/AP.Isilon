using Lextm.SharpSnmpLib;
using Microsoft.EnterpriseManagement.Common;
using Microsoft.EnterpriseManagement.Configuration;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AP.Isilon.Discovery.Classes
{
    class IsilonNode
    {
        // Position Indicators in ISI Command
        public static int ISI_NODE_ID = 0;
        public static int ISI_NIC_NAME = 1;
        public static int ISI_NIC_STATUS = 2;
        public static int ISI_SUBNET_NAME = 3;
        public static int ISI_IP_ADDRESS = 4;

        // Node Status
        public const int SNMP_NODE_NAME = 0;
        public const int SNMP_NODE_HEALTH = 1;
        public const int SNMP_NODE_TYPE = 2;
        public const int SNMP_NODE_READONLY = 3;

        // Node SCOM Object
        public CreatableEnterpriseManagementObject SCOM_Object;

        // List of Network Interfaces
        public List<IsilonNetworkInterface> NetworkInterfaceList = new List<IsilonNetworkInterface>();

        /// <summary>
        /// Default Constructor
        /// </summary>
        /// <param name="clusterName">Name of Hosting Cluster (KEY)</param>
        /// <param name="NodeIndex">Index of Node</param>
        /// <param name="interfaces">List of Network Interfaces</param>
        /// <param name="address">SNMP IP Address</param>
        /// <param name="community">SNMP Community</param>
        public IsilonNode(string clusterName, int NodeIndex, IsilonNetworkInterface[] interfaces, string address, string community)
        {
            string IPAddress = "";
            string NodeName = "Node" + NodeIndex.ToString();
            string IsilonNodeName = "";
            bool ReadOnly = false;
            string Type = "";

            // Save Network Interface List (Ignore Interfaces without IP Addresses)
            for (int i = 0; i < interfaces.Length; i++)
            {
                if (interfaces[i].ip_addrs.Length != 0)
                {
                    NetworkInterfaceList.Add(interfaces[i]);
                    if (interfaces[i].status.ToLower() == "up")
                    {
                        if (!interfaces[i].name.ToLower().Contains("mgmt"))
                        {
                            IPAddress = interfaces[i].ip_addrs[0];
                        }
                    }
                }
            }

            if (IPAddress != "")
            {
                try
                {
                    // Get Node Status Info
                    List<Variable> nodeStatus = SNMP.WalkSNMP(SNMP.nodeStatus, IPAddress, 161, community);
                    if (nodeStatus.Count!=0)
                    {
                        IsilonNodeName = nodeStatus[SNMP_NODE_NAME].Data.ToString();
                        if (nodeStatus[SNMP_NODE_READONLY].Data.ToString() == "1")
                        {
                            ReadOnly = true;
                        }
                        if (nodeStatus[SNMP_NODE_TYPE].Data.ToString() == "1")
                        {
                            Type = "Accelerator";
                        }
                        else
                        {
                            Type = "Storage";
                        }
                    }
                }
                catch (Exception ex)
                {
                    Program.log.Error(ex.Message);
                }

                try
                {
                    // Get Interface Descriptions via SNMP
                    List<Variable> snmpInterfaceDescriptions = SNMP.WalkSNMP(SNMP.ifTable, IPAddress, 161, community);

                    foreach (IsilonNetworkInterface nif in NetworkInterfaceList)
                    {
                        foreach (Variable var in snmpInterfaceDescriptions)
                        {
                            // Get Description
                            string desc = var.Data.ToString().ToLower();
                            // Get OidSuffix by removing the Table OID
                            string suffix = var.Id.ToString().Replace(SNMP.ifTable.TrimStart('.')+".", "");

                            // If name Matches then Store Suffix
                            if (nif.nic_name.ToLower() == desc)
                            {
                                nif.index = Convert.ToInt32(suffix);
                                break;
                            }
                        }
                        // Create Network Interface SCOM_Object
                        nif.CreateScomObject(clusterName, NodeName);
                    }

                }
                catch (Exception ex)
                {
                    Program.log.Error(ex.Message);
                }


                // Create Root Entity Class & Display Name Prop
                ManagementPackClass mpc_Entity = SCOM.GetManagementPackClass("System.Entity");
                ManagementPackProperty mpp_EntityDisplayName = mpc_Entity.PropertyCollection["DisplayName"];

                // Create Node Management Pack Class
                ManagementPackClass mpc_Node = SCOM.GetManagementPackClass("AP.Isilon.Node");
                // Create New NetworkInterface Object
                SCOM_Object = new CreatableEnterpriseManagementObject(SCOM.m_managementGroup, mpc_Node);

                // Display Name of Root Entity (KEY Property)
                SCOM_Object[mpp_EntityDisplayName].Value = NodeName;

                // Create Isilon Cluster Class & Name Prop
                ManagementPackClass mpc_Cluster = SCOM.GetManagementPackClass("AP.Isilon.Cluster");
                ManagementPackProperty mpp_ClusterName = mpc_Cluster.PropertyCollection["Name"];
                // Set parent Cluster Property
                SCOM_Object[mpp_ClusterName].Value = clusterName;

                // Now Create Properties for this node 
                // Name Property (KEY Property)
                ManagementPackProperty mpp_NodeName = mpc_Node.PropertyCollection["Name"];
                SCOM_Object[mpp_NodeName].Value = NodeName;
                // Index 
                ManagementPackProperty mpp_NodeIndex = mpc_Node.PropertyCollection["Index"];
                SCOM_Object[mpp_NodeIndex].Value = NodeIndex;
                // IP Address Property
                ManagementPackProperty mpp_NodeIPAddress = mpc_Node.PropertyCollection["IPAddress"];
                SCOM_Object[mpp_NodeIPAddress].Value = IPAddress;
                // Isilon Node Name Property
                ManagementPackProperty mpp_IsilonNodeName = mpc_Node.PropertyCollection["IsilonNodeName"];
                SCOM_Object[mpp_IsilonNodeName].Value = IsilonNodeName;
                // Type Property
                ManagementPackProperty mpp_Nodetype = mpc_Node.PropertyCollection["Type"];
                SCOM_Object[mpp_Nodetype].Value = Type;
                // ReadOnly Property
                ManagementPackProperty mpp_NodeReadOnly = mpc_Node.PropertyCollection["ReadOnly"];
                SCOM_Object[mpp_NodeReadOnly].Value = ReadOnly;
            }
        }
    }
}
