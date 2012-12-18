<%@ Page Language="C#" Buffer="false" %>
<!DOCTYPE HTML>
<html>
<head>
    <style type="text/css" media="screen">
        body {
            padding: 0px;
            margin: 0px;
        }

        .page {
            width: 800px;
            margin-left: auto;
            margin-right: auto;
        }

        .header {
            background-color: #64AA2B;
            height: 50px;
            padding: 0px;
            margin: 0px;
        }

        .headerStrip {
            background-color: #439400;
            height: 10px;
        }

        .headerTitle {
            color: #ffffff;
            font-family: "MS Sans Serif", Geneva, sans-serif;
            font-size: 16px;
            position: relative;
            left: 15px;
            top: 15px;
        }

        .mainContent {
            margin: 0px;
            font-family: "MS Sans Serif", Geneva, sans-serif;
        }

        .contentSection {
            margin: 0px;
        }

        table {
            font-family: "MS Sans Serif", Geneva, sans-serif;
            font-size: 12px;
            border-spacing: 0px;
            max-width: 100%;
            width: 100%;
            margin-left: auto;
            margin-right: auto;
            margin-bottom: 10px;
        }

            table th {
                background-color: #C9F76F;
                padding: 10px 5px 5px 5px;
                font-weight: normal;
                text-align: left;
            }

            table td {
                background-color: #ffffff;
                padding: 2px 2px 2px 15px;
                vertical-align: top;
            }
    </style>
    <title>ASP.NET Host Script</title>

    <script runat="server">
        public Version GetIISVersion()
        {
            using (Microsoft.Win32.RegistryKey componentsKey = Microsoft.Win32.Registry.LocalMachine.OpenSubKey(@"Software\Microsoft\InetStp", false))
            {
                if (componentsKey != null)
                {
                    int majorVersion = (int)componentsKey.GetValue("MajorVersion", -1);
                    int minorVersion = (int)componentsKey.GetValue("MinorVersion", -1);

                    if (majorVersion != -1 && minorVersion != -1)
                    {
                        return new Version(majorVersion, minorVersion);
                    }
                }
                return new Version(0, 0);
            }
        }

        private System.Collections.Generic.List<string> DotNetInstalled()
        {
            System.Collections.Generic.List<string> installed = new System.Collections.Generic.List<string>();
            Microsoft.Win32.RegistryKey componentsKey = null;
            string v;

            System.Collections.Generic.List<string> keys = new System.Collections.Generic.List<string>();
            keys.Add(@"SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Client");
            keys.Add(@"SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full");
            keys.Add(@"SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5");
            keys.Add(@"SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.0");
            keys.Add(@"SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727");
            keys.Add(@"SOFTWARE\Microsoft\NET Framework Setup\NDP\v1.1.4322");
            keys.Add(@"SOFTWARE\Microsoft\Active Setup\Installed Components\{78705f0d-e8db-4b2d-8193-982bdda15ecd}");

            foreach (string key in keys)
            {
                componentsKey = Microsoft.Win32.Registry.LocalMachine.OpenSubKey(key);
                if (componentsKey != null)
                {
                    short installVal = Convert.ToInt16(componentsKey.GetValue("Install"));
                    short spVal = Convert.ToInt16(componentsKey.GetValue("SP"));
                    string versionVal = componentsKey.GetValue("Version") as string;

                    if (installVal == 1)
                    {
                        string cf = key.Contains(@"\Client") ? "Client Profile" : "";

                        if (spVal == 0)
                        {
                            v = string.Format(".NET {0} [{1}]", versionVal, cf).Replace("[]", string.Empty).Trim();
                        }
                        else
                        {
                            v = string.Format(".NET {0} (SP{1}) [{2}]", versionVal, spVal, cf).Replace("[]", string.Empty).Trim();
                        }

                        installed.Add(v);
                    }
                }
            }

            return installed;
        }
</script>

</head>
<body>
    <div class="page">
        <div class="header">
            <div class="headerTitle">
                ASP.NET Host Script
            </div>
        </div>
        <div class="headerStrip">
        </div>
        <div class="mainContent">
            <div class="contentSection">
                <table>
                                        <tr>
                        <th colspan="2">.Net
                        </th>
                    </tr>
                    <tr>
                        <td>.Net Versions Installed (from filesystem)
                        </td>
                        <td>
                            <%
                                string[] versions = System.IO.Directory.GetDirectories(@"C:\Windows\Microsoft.NET\Framework", "v*");
                                string version = "Unknown";

                                for (int i = versions.Length - 1; i >= 0; i--)
                                {
                                    int startIndex = versions[i].LastIndexOf("\\") + 2;
                                    version = versions[i].Substring(startIndex, versions[i].Length - startIndex);
                                    if (version.Contains("."))
                                    {
                                        Response.Write(string.Format("<div style=\"padding:2px 2px 2px 0px;\">{0}</div>", version));
                                    }
                                }
                            %>
                        </td>
                    </tr>

                     <tr>
                        <td>.Net Versions Installed (from registry)
                        </td>
                        <td>
                            <%
                                string[] versions2 = DotNetInstalled().ToArray();
                                string version2 = "Unknown";

                                for (int i = versions2.Length - 1; i >= 0; i--)
                                {
                                    int startIndex = versions2[i].LastIndexOf("\\") + 2;
                                    version2 = versions2[i].Substring(startIndex, versions2[i].Length - startIndex);
                                    if (version2.Contains("."))
                                    {
                                        Response.Write(string.Format("<div style=\"padding:2px 2px 2px 0px;\">{0}</div>", version2));
                                    }
                                }
                            %>
                        </td>
                    </tr>


                    <tr>
                        <th colspan="2">Environment
                        </th>
                    </tr>
                    <tr>
                        <td>Environment.MachineName
                        </td>
                        <td>
                            <%= Environment.MachineName %>
                        </td>
                    </tr>
                    <tr>
                        <td>Environment.OSVersion.VersionString
                        </td>
                        <td>
                            <%= Environment.OSVersion.VersionString %>
                        </td>
                    </tr>
                    <tr>
                        <td>Environment.ProcessorCount
                        </td>
                        <td>
                            <%= Environment.ProcessorCount %>
                        </td>
                    </tr>
                    <tr>
                        <td>Environment.SystemDirectory
                        </td>
                        <td>
                            <%= Environment.SystemDirectory %>
                        </td>
                    </tr>
                    <tr>
                        <td>Environment.UserDomainName
                        </td>
                        <td>
                            <%= Environment.UserDomainName %>
                        </td>
                    </tr>
                    <tr>
                        <td>Environment.UserName
                        </td>
                        <td>
                            <%= Environment.UserName %>
                        </td>
                    </tr>
                    <tr>
                        <td>Environment.Version
                        </td>
                        <td>
                            <%= Environment.Version.ToString() %>
                        </td>
                    </tr>
                    <tr>
                        <th colspan="2">Request
                        </th>
                    </tr>
                    <tr>
                        <td>Request.ApplicationPath
                        </td>
                        <td>
                            <%= Request.ApplicationPath %>
                        </td>
                    </tr>
                    <tr>
                        <td>Request.AppRelativeCurrentExecutionFilePath
                        </td>
                        <td>
                            <%= Request.AppRelativeCurrentExecutionFilePath %>
                        </td>
                    </tr>
                    <tr>
                        <td>Request.CurrentExecutionFilePath
                        </td>
                        <td>
                            <%= Request.CurrentExecutionFilePath %>
                        </td>
                    </tr>
                    <tr>
                        <td>Request.FilePath
                        </td>
                        <td>
                            <%= Request.FilePath %>
                        </td>
                    </tr>
                    <tr>
                        <td>Request.HttpMethod
                        </td>
                        <td>
                            <%= Request.HttpMethod %>
                        </td>
                    </tr>
                    <tr>
                        <td>Request.IsSecureConnection
                        </td>
                        <td>
                            <%= Request.IsSecureConnection %>
                        </td>
                    </tr>
                    <tr>
                        <td>Request.LogonUserIdentity
                        </td>
                        <td>
                            <%= Request.LogonUserIdentity.Name %>
                        </td>
                    </tr>
                    <tr>
                        <td>Request.Path
                        </td>
                        <td>
                            <%= Request.Path %>
                        </td>
                    </tr>
                    <tr>
                        <td>Request.PathInfo
                        </td>
                        <td>
                            <%= Request.PathInfo %>
                        </td>
                    </tr>
                    <tr>
                        <td>Request.PhysicalApplicationPath
                        </td>
                        <td>
                            <%= Request.PhysicalApplicationPath %>
                        </td>
                    </tr>
                    <tr>
                        <td>Request.PhysicalPath
                        </td>
                        <td>
                            <%= Request.PhysicalPath %>
                        </td>
                    </tr>
                    <tr>
                        <td>Request.RequestType
                        </td>
                        <td>
                            <%= Request.RequestType %>
                        </td>
                    </tr>
                    <tr>
                        <td>Request.Url
                        </td>
                        <td>
                            <%= Request.Url.ToString() %>
                        </td>
                    </tr>
                    <tr>
                        <td>Request.UrlReferrer
                        </td>
                        <td>
                            <%= Request.UrlReferrer != null ? Request.UrlReferrer.ToString() : "" %>
                        </td>
                    </tr>
                    <tr>
                        <td>Request.UserAgent
                        </td>
                        <td>
                            <%= Request.UserAgent %>
                        </td>
                    </tr>
                    <tr>
                        <td>Request.UserHostAddress
                        </td>
                        <td>
                            <%= Request.UserHostAddress %>
                        </td>
                    </tr>
                    <tr>
                        <td>Request.UserHostName
                        </td>
                        <td>
                            <%= Request.UserHostName %>
                        </td>
                    </tr>
                    <tr>
                        <td>Request.Headers
                        </td>
                        <td>
                            <% foreach (string key in Request.Headers.AllKeys)
                               {
                                   string headerValue = Request.Headers[key];
                                   if (!string.IsNullOrEmpty(headerValue))
                                   {
                                       Response.Write(string.Format("<div style=\"float:left;min-width:25%;padding:2px 2px 2px 0px;\">{0}</div><div style=\"padding:2px 2px 2px 0px;\">{1}</div>", key.Trim(), Request.Headers[key].Trim()));
                                   }
                               }
                            %>
                        </td>
                    </tr>
                                        <tr>
                        <td>Request.ServerVariables
                        </td>
                        <td>
                            <% foreach (string key in Request.ServerVariables.AllKeys)
                               {
                                   string headerValue = Request.ServerVariables[key];
                                   if (!string.IsNullOrEmpty(headerValue))
                                   {
                                       Response.Write(string.Format("<div style=\"float:left;min-width:25%;padding:2px 2px 2px 0px;\">{0}</div><div style=\"padding:2px 2px 2px 0px;\">{1}</div>", key.Trim(), Request.ServerVariables[key].Trim()));
                                   }
                               }
                            %>
                        </td>
                    </tr>
                    <% if (HttpRuntime.UsingIntegratedPipeline) 
                       {
                            %>
                    <tr>
                        <th colspan="2">Response
                        </th>
                    </tr>
                    <tr>
                        <td>Response.Headers
                        </td>
                        <td>
                            <% foreach (string key in Response.Headers.AllKeys)
                               {
                                   string headerValue = Response.Headers[key];
                                   if (!string.IsNullOrEmpty(headerValue))
                                   {
                                       Response.Write(string.Format("<div style=\"float:left;min-width:25%;padding:2px 2px 2px 0px;\">{0}</div><div style=\"padding:2px 2px 2px 0px;\">{1}</div>", key.Trim(), Response.Headers[key].Trim()));
                                   }
                               }
                            %>
                        </td>
                    </tr>
                    <% } %>
                    <tr>
                        <th colspan="2">IIS
                        </th>
                    </tr>
                    <tr>
                        <td>IIS Version
                        </td>
                        <td>
                            <% Response.Write(GetIISVersion()); %>
                        </td>
                    </tr>
                    <tr>
                        <td>HttpRuntime.UsingIntegratedPipeline
                        </td>
                        <td>
                            <% Response.Write(HttpRuntime.UsingIntegratedPipeline); %>
                        </td>
                    </tr>

                    <tr>
                        <th colspan="2">GAC
                        </th>
                    </tr>
                    <tr>
                        <td>Assemblies
                        </td>
                        <td>
                            <% try
                               {
                                   string windows = Environment.GetEnvironmentVariable("SystemRoot");
                                   string assembly = System.IO.Path.Combine(windows, @"assembly");
                                   string[] gacFolders = System.IO.Directory.GetDirectories(assembly);

                                   System.Collections.Generic.List<string> allAssemblies = new System.Collections.Generic.List<string>();
                                   foreach (string folder in gacFolders)
                                   {
                                       if (folder.ToLowerInvariant().Contains("\\gac"))
                                       {
                                           string path = System.IO.Path.Combine(assembly, folder);
                                           if (System.IO.Directory.Exists(path))
                                           {
                                               string[] assemblyFolders = System.IO.Directory.GetDirectories(path);

                                               if (assemblyFolders != null && assemblyFolders.Length > 0)
                                               {
                                                   foreach (string assemblyFolder in assemblyFolders)
                                                   {
                                                       string dllName = assemblyFolder.Replace(path, "").Replace(@"\", "") + ".dll";
                                                       if (!allAssemblies.Contains(dllName))
                                                       {
                                                           allAssemblies.Add(dllName);
                                                       }
                                                   }
                                               }
                                           }
                                       }
                                   }
                                   allAssemblies.Sort();

                                   foreach (string dll in allAssemblies)
                                   {
                                       Response.Write(string.Format("<div style=\"padding:2px 2px 2px 0px;\">{0}</div>", dll));
                                   }
                               }
                               catch (NotSupportedException ex) { Response.Write(ex.Message); }
                            %>
                        </td>
                    </tr>
                </table>
            </div>
        </div>
    </div>
</body>
</html>
