using Lextm.SharpSnmpLib;
using Lextm.SharpSnmpLib.Messaging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;

namespace AP.Isilon.Discovery.Classes
{
    public class SNMP
    {
        // .iso.org.dod.internet.mgmt.mib-2.system.sysObjectID
        public const string sysObjectID = ".1.3.6.1.2.1.1.2.0";

        // .iso.org.dod.internet.mgmt.mib-2.system.sysLocation
        public const string sysLocation = ".1.3.6.1.2.1.1.6.0";

        // .iso.org.dod.internet.mgmt.mib-2.system.sysContact
        public const string sysContact = ".1.3.6.1.2.1.1.4.0";

        //=====================================================
        // EMC ISILON OIDs
        //=====================================================

        // .iso.org.dod.internet.private.enterprises.isilon.cluster.clusterStatus.clusterName
        public const string clusterName = ".1.3.6.1.4.1.12124.1.1.1.0";

        // .iso.org.dod.internet.private.enterprises.isilon.cluster.clusterStatus.clusterGUID
        public const string clusterGUID = ".1.3.6.1.4.1.12124.1.1.3.0";

        // .iso.org.dod.internet.private.enterprises.isilon.cluster.clusterStatus.nodeCount
        public const string nodeCount = ".1.3.6.1.4.1.12124.1.1.4.0";

        // .iso.org.dod.internet.private.enterprises.isilon.cluster.clusterStatus.configuredNodes
        public const string configuredNodes = ".1.3.6.1.4.1.12124.1.1.5.0";

        // .iso.org.dod.internet.private.enterprises.isilon.cluster.clusterStatus.configuredNodes
        public const string onlineNodes = ".1.3.6.1.4.1.12124.1.1.6.0";

        // .iso.org.dod.internet.private.enterprises.isilon.cluster.clusterStatus.offlineNodes
        public const string offlineNodes = ".1.3.6.1.4.1.12124.1.1.7.0";

        // .iso.org.dod.internet.mgmt.mib-2.interfaces.ifTable.ifEntry.ifDescr
        public const string ifTable = ".1.3.6.1.2.1.2.2.1.2";

        // .iso.org.dod.internet.private.enterprises.isilon.node.nodeStatus
        public const string nodeStatus = ".1.3.6.1.4.1.12124.2.1";

        // .iso.org.dod.internet.private.enterprises.isilon.node.nodeStatus.nodeHealth
        public const string nodeHealth = ".1.3.6.1.4.1.12124.2.1.2.0";

        // .iso.org.dod.internet.private.enterprises.isilon.node.diskTable.diskEntry.diskBay
        public const string diskBay = ".1.3.6.1.4.1.12124.2.52.1.1";

        // .iso.org.dod.internet.private.enterprises.isilon.node.diskTable.diskEntry.diskLogicalNumber
        public const string diskLogicalNumber = ".1.3.6.1.4.1.12124.2.52.1.2";

        // .iso.org.dod.internet.private.enterprises.isilon.node.diskTable.diskEntry.diskChassisNumber
        public const string diskChassisNumber = ".1.3.6.1.4.1.12124.2.52.1.3";

        // .iso.org.dod.internet.private.enterprises.isilon.node.diskTable.diskEntry.diskDeviceName
        public const string diskDeviceName = ".1.3.6.1.4.1.12124.2.52.1.4";

        // .iso.org.dod.internet.private.enterprises.isilon.node.diskTable.diskEntry.diskModel
        public const string diskModel = ".1.3.6.1.4.1.12124.2.52.1.6";

        // .iso.org.dod.internet.private.enterprises.isilon.node.diskTable.diskEntry.diskSerialNumber
        public const string diskSerialNumber = ".1.3.6.1.4.1.12124.2.52.1.7";

        // .iso.org.dod.internet.private.enterprises.isilon.node.diskTable.diskEntry.diskFirmwareVersion
        public const string diskFirmwareVersion = ".1.3.6.1.4.1.12124.2.52.1.8";

        // .iso.org.dod.internet.private.enterprises.isilon.node.diskTable.diskEntry.diskSizeBytes
        public const string diskSizeBytes = ".1.3.6.1.4.1.12124.2.52.1.9";

        // .iso.org.dod.internet.private.enterprises.isilon.node.nodePerformance.nodeProtocolPerfTable.nodeProtocolPerfEntry.protocolName
        public const string protocolName = ".1.3.6.1.4.1.12124.2.2.10.1.1";

        // .iso.org.dod.internet.private.enterprises.isilon.cluster.ifsFilesystem.ifsTotalBytes
        public const string ifsTotalBytes = ".1.3.6.1.4.1.12124.1.3.1.0";

        // .iso.org.dod.internet.private.enterprises.isilon.cluster.ifsFilesystem.ifsUsedBytes
        public const string ifsUsedBytes = ".1.3.6.1.4.1.12124.1.3.2.0";

        // .iso.org.dod.internet.private.enterprises.isilon.cluster.ifsFilesystem.ifsAvailableBytes
        public const string ifsAvailableBytes = ".1.3.6.1.4.1.12124.1.3.3.0";

        // .iso.org.dod.internet.private.enterprises.isilon.node.tempSensorTable.tempSensorEntry.tempSensorNumber
        public const string tempSensorNumber = ".1.3.6.1.4.1.12124.2.54.1.1";

        // .iso.org.dod.internet.private.enterprises.isilon.node.tempSensorTable.tempSensorEntry.tempSensorName
        public const string tempSensorName = ".1.3.6.1.4.1.12124.2.54.1.2";

        // .iso.org.dod.internet.private.enterprises.isilon.node.tempSensorTable.tempSensorEntry.tempSensorValue
        public const string tempSensorValue = ".1.3.6.1.4.1.12124.2.54.1.4";

        #region "SNMP_Functions"
        /// <summary>
        /// Get Single SNMP OID
        /// </summary>
        /// <param name="inputoid"></param>
        /// <returns></returns>
        public static List<Variable> GetSNMP(string inputoid, string address, int port, string community)
        {
            List<Variable> retlist = new List<Variable>();

            try
            {
                var response = Messenger.Get(VersionCode.V2,
                   new IPEndPoint(IPAddress.Parse(address), port),
                   new OctetString(community),
                   new List<Variable> { new Variable(new ObjectIdentifier(inputoid)) },
                   10000);
                retlist = response.ToList();
            }
            catch (Exception)
            {
            }
            return retlist;
        }


        /// <summary>
        /// Get Bulk SNMP
        /// </summary>
        /// <param name="inputoid"></param>
        /// <returns></returns>
        public static List<Variable> BulkSNMP(string inputoid, string address, int port, string community)
        {
            List<Variable> retlist = new List<Variable>();

            try
            {
                GetBulkRequestMessage message = new GetBulkRequestMessage(0,
                                                              VersionCode.V2,
                                                              new OctetString(community),
                                                              0,
                                                              255,
                                                              new List<Variable> { new Variable(new ObjectIdentifier(inputoid)) });
                ISnmpMessage response = message.GetResponse(60000, new IPEndPoint(IPAddress.Parse(address), port));
                if (response.Pdu().ErrorStatus.ToInt32() != 0)
                {
                    throw ErrorException.Create(
                        "error in response",
                        IPAddress.Parse(address),
                        response);

                }
                retlist = response.Pdu().Variables.ToList();

            }
            catch (Exception)
            {
            }
            return retlist;
        }

        /// <summary>
        /// Walk SNMP
        /// </summary>
        /// <param name="inputoid"></param>
        /// <returns></returns>
        public static List<Variable> WalkSNMP(string inputoid, string address, int port, string community)
        {
            List<Variable> retlist = new List<Variable>();

            try
            {
                Messenger.Walk(VersionCode.V2,
                   new IPEndPoint(IPAddress.Parse(address), port),
                   new OctetString(community),
                   new ObjectIdentifier(inputoid),
                   retlist,
                   10000, WalkMode.WithinSubtree);
            }
            catch (Exception ex)
            {
                string message = ex.Message;
            }
            return retlist;
        }

        #endregion
    }
}
