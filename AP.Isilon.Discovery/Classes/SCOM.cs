using Microsoft.EnterpriseManagement;
using Microsoft.EnterpriseManagement.Configuration;
using Microsoft.EnterpriseManagement.ConnectorFramework;
using System;
using System.Collections.Generic;

namespace AP.Isilon.Discovery.Classes
{
    class SCOM
    {
        // SCOM Management Group
        public static ManagementGroup m_managementGroup { get; set; }
        public static MonitoringConnector m_monitoringConnector { get; set; }

        /// <summary>
        /// Create a SCOM Connector
        /// </summary>
        public static void CreateConnector()
        {

            Guid connectorGuid = new Guid("B7746650-70AA-4B4B-8E33-F5E4F0AA679E");

            IConnectorFrameworkManagement cfMgmt = m_managementGroup.ConnectorFramework;

            try
            {
                m_monitoringConnector = cfMgmt.GetConnector(connectorGuid);
            }
            catch (Microsoft.EnterpriseManagement.Common.ObjectNotFoundException)
            {
                //The connector does not exist, so create it.

                ConnectorInfo connectorInfo = new ConnectorInfo
                {
                    Description = "This Connector is to Discover EMC Isilon Information",
                    DisplayName = "AP EMC Isilon Connector",
                    Name = "AP.Isilon.Connector"
                };

                m_monitoringConnector = cfMgmt.Setup(connectorInfo, connectorGuid);
            }

            if (!m_monitoringConnector.Initialized)
            {
                m_monitoringConnector.Initialize();
            }
        }

        /// <summary>
        /// Get Management Pack Class
        /// </summary>
        /// <param name="className">Class Name to Find</param>
        /// <returns></returns>
        public static ManagementPackClass GetManagementPackClass(string className)
        {
            IList<ManagementPackClass> mpClasses;

            mpClasses = m_managementGroup.EntityTypes.GetClasses(new ManagementPackClassCriteria("Name='" + className + "'"));

            if (mpClasses.Count == 0)
            {
                throw new ApplicationException("Failed to find management pack class " + className);
            }

            return (mpClasses[0]);
        }

        /// <summary>
        /// Get Management Pack Relationship
        /// </summary>
        /// <param name="relationshipName">Relationship Name to Find</param>
        /// <returns></returns>
        public static ManagementPackRelationship GetManagementPackRelationship(string relationshipName)
        {
            IList<ManagementPackRelationship> relationshipClasses;

            relationshipClasses = m_managementGroup.EntityTypes.GetRelationshipClasses(new ManagementPackRelationshipCriteria("Name='" + relationshipName + "'"));

            if (relationshipClasses.Count == 0)
            {
                throw new ApplicationException("Failed to find monitoring relationship " + relationshipName);
            }

            return (relationshipClasses[0]);
        }

    }
}
