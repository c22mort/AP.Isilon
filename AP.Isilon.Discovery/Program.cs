using AP.Isilon.Discovery.Classes;
using LumenWorks.Framework.IO.Csv;
using Microsoft.EnterpriseManagement;
using Microsoft.EnterpriseManagement.ConnectorFramework;
using System;
using System.Collections.Generic;
using System.IO;

namespace AP.Isilon.Discovery
{
    class Program
    {
        // CSV Position Indicators
        public static int CSV_ADDRESS = 0;
        public static int CSV_COMMUNITY = 1;
        public static int CSV_USER = 2;
        public static int CSV_PASSWORD = 3;

        // SCOM Instance
        private static SCOM scom = new SCOM();

        // log4net Instance
        public static readonly log4net.ILog log = log4net.LogManager.GetLogger(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        // Config File Name
        private static string m_configFileName = "config.csv";

        // Clusters File Name
        private static string m_clusterFileName = "clusters.csv";

        // Management Server Name
        private static string m_managementServer;

        // Create Snapshot Discovery Data Object
        private static SnapshotDiscoveryData discoData = new SnapshotDiscoveryData();

        // List of Isilon Clusters
        private static List<IsilonCluster> ClusterList = new List<IsilonCluster>();

        /// <summary>
        /// Application Entry Point
        /// </summary>
        /// <param name="args"></param>
        static void Main(string[] args)
        {
            // Write Header
            Console.WriteLine("AP.EMC.Isilon.Discovery, ©A.Patrick 2017-2018");
            Console.WriteLine("Discovers EMC Isilon Clusters and Nodes for SCOM.");
            Console.WriteLine("");

            // First Thing is to get the Managment Server Name from the config file (if it exists)
            m_managementServer = GetManagementServer();

            if (File.Exists(m_clusterFileName))
            {
                // Write Discovered Data to SCOM Database ( For Relationships
                log.Info("Creating Inbound Connector to " + m_managementServer + "...");

                // Get Management Group
                SCOM.m_managementGroup = new ManagementGroup(m_managementServer);

                // Create Our Inbound Connector
                SCOM.CreateConnector();

                // Make Sure Connector is initialized
                if (SCOM.m_monitoringConnector.Initialized)
                {
                    // Get Clusters and Nodes
                    log.Info("Starting Cluster & Node Discovery...");
                    GetClustersAndNodes();

                    // Add in Discovery Data
                    foreach (IsilonCluster ic in ClusterList)
                    {
                        discoData.Include(ic.SCOM_Object);
                        foreach (IsilonNode node in ic.NodeList)
                        {
                            discoData.Include(node.SCOM_Object);
                            foreach (IsilonNetworkInterface nif in node.NetworkInterfaceList)
                            {
                                discoData.Include(nif.SCOM_Object);
                            }
                        }
                    }
                    
                    // Get Clusters and Nodes
                    log.Info("Writing Discovery data to " + m_managementServer + "...");
                    discoData.Overwrite(SCOM.m_monitoringConnector);

                    // Free Connector
                    SCOM.m_monitoringConnector.Uninitialize();
                    SCOM.m_monitoringConnector = null;

                } else
                {
                    log.Fatal("Couldn't Initialize Inbound SCOM Connector!");
                    if (SCOM.m_monitoringConnector!=null)
                    {
                        SCOM.m_monitoringConnector = null;
                    }
                    Environment.Exit(5);
                }

            } else
            {
                log.Fatal("Could not find cluster file, " + m_clusterFileName);
                Environment.Exit(5);
            }

        }

        /// <summary>
        /// Get Management Server
        /// </summary>
        /// <returns>Name of Management Server to Conenct to, localhost if config.csv cannot be found or no entry</returns>
        private static string GetManagementServer()
        {
            // Set to default of localhost
            string mserver = "localhost";

            // See if File Exists
            if (!File.Exists(m_configFileName))
            {
                log.Info("Could not find Config File, config.csv, will use locahost as Management Server Name.");
                return mserver;
            }

            // Load In CSV File
            CsvReader csv = new CsvReader(new StreamReader(m_configFileName), true);
            if (csv.FieldCount == 0)
            {
                log.Info("Config File, config.csv, seems to have no fields please check, will use locahost as Management Server Name.");
            }
            else
            {
                // Read First Record
                csv.ReadNextRecord();
                // Get Management Server Name
                mserver = csv[0].ToString();
            }

            // Dispose of CSV Handler
            csv.Dispose();

            // Return Management Server Name
            return mserver;
        }

        /// <summary>
        /// Get Clusters And Nodes
        /// </summary>
        private static void GetClustersAndNodes()
        {
            // Load In CSV File
            CsvReader csv = new CsvReader(new StreamReader(m_clusterFileName), true);
            while (csv.ReadNextRecord())
            {
                // Show Info
                log.Info("Discovering " + csv[CSV_ADDRESS] + "...");

                // Create new Isilon Cluster
                IsilonCluster newCluster = new IsilonCluster(csv[CSV_ADDRESS], csv[CSV_COMMUNITY], csv[CSV_USER], csv[CSV_PASSWORD]);
                ClusterList.Add(newCluster);
            }
            csv.Dispose();

        }
    }
}
