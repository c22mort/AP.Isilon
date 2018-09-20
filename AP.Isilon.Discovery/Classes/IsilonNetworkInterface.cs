using AP.Isilon.Discovery.Classes;
using Microsoft.EnterpriseManagement.Common;
using Microsoft.EnterpriseManagement.Configuration;

namespace AP.Isilon.Discovery.Classes
{

    class IsilonNetworkInterface
    {
        // Properties Used For JSON De-Serialisation
        public string status { get; set; }
        public string[] owners { get; set; }
        public string name { get; set; }
        public string nic_name { get; set; }
        public string[] ip_addrs { get; set; }
        public int lnn { get; set; }
        public string type { get; set; }
        public string id { get; set; }
        public int index { get; set; }
        // Position Indicators in ISI Command
        public static int ISI_NODE_ID = 0;
        public static int ISI_NIC_NAME = 1;
        public static int ISI_NIC_STATUS = 2;
        public static int ISI_SUBNET_NAME = 3;
        public static int ISI_IP_ADDRESS = 4;

        // NetworkInterface SCOM Object
        public CreatableEnterpriseManagementObject SCOM_Object;


        /// <summary>
        /// Default Constructor
        /// </summary>
        public void CreateScomObject(string clusterName, string NodeName)
        {

            // Create Root Entity Class & Display Name Prop
            ManagementPackClass mpc_Entity = SCOM.GetManagementPackClass("System.Entity");
            ManagementPackProperty mpp_EntityDisplayName = mpc_Entity.PropertyCollection["DisplayName"];

            // Create NetworkInterface Management Pack Class
            ManagementPackClass mpc_NetworkInterface = SCOM.GetManagementPackClass("AP.Isilon.NetworkInterface");
            // Create New NetworkInterface Object
            SCOM_Object = new CreatableEnterpriseManagementObject(SCOM.m_managementGroup, mpc_NetworkInterface);

            // Display Name of Root Entity (KEY Property)
            SCOM_Object[mpp_EntityDisplayName].Value = name;

            // Create Isilon Node Class & Index Prop
            ManagementPackClass mpc_Node = SCOM.GetManagementPackClass("AP.Isilon.Node");
            ManagementPackProperty mpp_NodeName = mpc_Node.PropertyCollection["Name"];
            // Set Parent Node Key Property
            SCOM_Object[mpp_NodeName].Value = NodeName;

            // Create Isilon Cluster Class & Name Prop
            ManagementPackClass mpc_Cluster = SCOM.GetManagementPackClass("AP.Isilon.Cluster");
            ManagementPackProperty mpp_ClusterName = mpc_Cluster.PropertyCollection["Name"];
            // Set Parent Cluster Key Property
            SCOM_Object[mpp_ClusterName].Value = clusterName;

            // Now we Can Set Properties of the Network Interface
            ManagementPackProperty mpp_NetworkInterfaceName = mpc_NetworkInterface.PropertyCollection["Name"];
            SCOM_Object[mpp_NetworkInterfaceName].Value = name;

            // IP Addresses
            string addresses = "";
            foreach (string address in ip_addrs)
            {
                addresses += address + ", ";
            }
            addresses = addresses.TrimEnd(new char[] { ',', ' ' });
            ManagementPackProperty mpp_NetworkInterfaceIPAddress = mpc_NetworkInterface.PropertyCollection["IPAddresses"];
            SCOM_Object[mpp_NetworkInterfaceIPAddress].Value = addresses;

            // SubNets
            string subnets = "";
            foreach (string owner in owners)
            {
                subnets += owner.Substring(owner.LastIndexOf('.')+1) + ", ";
            }
            subnets = subnets.TrimEnd(new char[] { ',', ' ' });
            ManagementPackProperty mpp_NetworkInterfaceSubnet = mpc_NetworkInterface.PropertyCollection["Subnets"];
            SCOM_Object[mpp_NetworkInterfaceSubnet].Value = subnets;

            ManagementPackProperty mpp_NetworkInterfaceIndex = mpc_NetworkInterface.PropertyCollection["Index"];
            SCOM_Object[mpp_NetworkInterfaceIndex].Value = index;

            ManagementPackProperty mpp_NetworkInterfaceNicName = mpc_NetworkInterface.PropertyCollection["NicName"];
            SCOM_Object[mpp_NetworkInterfaceNicName].Value = nic_name;

        }

    }
}
