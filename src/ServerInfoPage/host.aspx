<%@ Page Language="C#"
    Trace="false"
    Debug="false"
    AspCompat="true"
    CompilationMode="Always"
    CompilerOptions="/optimize+"
    Culture="en-AU"
    UICulture="en-AU"
    EnableSessionState="false"
    EnableViewState="false"
    EnableTheming="false"
    EnableViewStateMac="false"
    ValidateRequest="true" %>

<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Net.NetworkInformation" %>
<%@ Import Namespace="System.Web.Configuration" %>
<%@ Import Namespace="Microsoft.Win32" %>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <%--<meta name="viewport" content="width=device-width, initial-scale=1">--%>
    <meta name="description" content="ASP.NET Host Info Script">
    <link rel="stylesheet" type="text/css" href="http://maxcdn.bootstrapcdn.com/bootstrap/latest/css/bootstrap.min.css" />
    <title>ASP.NET Host Info Script</title>
    <script runat="server">

        private enum EndpointType
        {
            Udp,
            Tcp
        }

        class IPEndPointWithType : IPEndPoint
        {
            private EndpointType _endpointType;
            public EndpointType EndpointType
            {
                get { return _endpointType; }
            }

            public IPEndPointWithType(IPEndPoint ep, EndpointType type)
                : base(ep.Address, ep.Port)
            {
                _endpointType = type;
            }
        }

        private string HKLM_GetString(string path, string key)
        {
            string value = string.Empty;

            try
            {
                RegistryKey rk = Registry.LocalMachine.OpenSubKey(path);
                if (rk != null)
                {
                    value = rk.GetValue(key) as string;
                    rk.Close();
                }
            }
            catch
            {
                value = string.Empty;
            }

            return value;
        }

        public string FriendlyOsName()
        {
            string productName = HKLM_GetString(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion", "ProductName");
            string csdVersion = HKLM_GetString(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion", "CSDVersion");
            if (productName != string.Empty)
            {
                return (productName.StartsWith("Microsoft") ? string.Empty : "Microsoft ") + productName + (csdVersion != string.Empty ? " " + csdVersion : string.Empty);
            }
            return string.Empty;
        }

        public Version GetIisVersion()
        {
            using (RegistryKey componentsKey = Registry.LocalMachine.OpenSubKey(@"Software\Microsoft\InetStp", false))
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

        private List<string> DotNetInstalled()
        {
            List<string> installed = new List<string>();
            RegistryKey componentsKey = null;
            string v;

            List<string> keys = new List<string>();
            keys.Add(@"SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Client");
            keys.Add(@"SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full");
            keys.Add(@"SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5");
            keys.Add(@"SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.0");
            keys.Add(@"SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727");
            keys.Add(@"SOFTWARE\Microsoft\NET Framework Setup\NDP\v1.1.4322");
            keys.Add(@"SOFTWARE\Microsoft\Active Setup\Installed Components\{78705f0d-e8db-4b2d-8193-982bdda15ecd}");

            foreach (string key in keys)
            {
                componentsKey = Registry.LocalMachine.OpenSubKey(key);
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

        private int CompareEndpoints(IPEndPoint ep1, IPEndPoint ep2)
        {
            return ep1.Port.CompareTo(ep2.Port);
        }

        private int CompareStrings(string s, string s1)
        {
            return s.ToLowerInvariant().CompareTo(s1.ToLowerInvariant());
        }

    </script>
</head>
<body role="document" style="font-family: 'Trebuchet MS',Tahoma, Arial;">
    <a role="link" id="home"></a>
    <div class="container" role="main">
        <br />
        <ol class="breadcrumb" style="font-size: 0.75em;">
            <li><a href="#essentialInfo">Essential</a></li>
            <li><a href="#dotnetVersions">.NET</a></li>
            <li><a href="#activeListeners">Ports</a></li>
            <li><a href="#environmentVariables">Environment Vars</a></li>
            <li><a href="#requestProperties">Request Props</a></li>
            <li><a href="#requestHeaders">Request Headers</a></li>
            <li><a href="#responseHeaders">Response Headers</a></li>
            <li><a href="#serverVariables">Server Vars</a></li>
            <li><a href="#connectionStrings">Connection Strs</a></li>
            <li><a href="#appSettings">App Settings</a></li>
            <li><a href="#gac">GAC</a></li>
        </ol>
        <div class="panel panel-default">
            <div class="panel-heading">
                <h1><span class="glyphicon glyphicon-home" aria-hidden="true" style="font-size: 0.8em;"></span>&nbsp;<%= (Environment.MachineName + " (" + Request.ServerVariables["LOCAL_ADDR"] + ")") %></h1>
            </div>
            <div class="panel-body">
                <div>
                    <p class="text-muted small"><span class="glyphicon glyphicon-info-sign" aria-hidden="true"></span>&nbsp;The latest version of this script can be found @ <a href="https://github.com/fallenidol/ServerInfoPage" target="_blank">github.com/fallenidol/ServerInfoPage</a>.</p>
                    <a role="link" id="essentialInfo"></a>
                    <h3 class="text-primary">Essential Information<a href="#home" class="pull-right"><span class="glyphicon glyphicon-arrow-up small"></span></a></h3>
                    <table class="table table-striped">
                        <tbody>
                            <tr>
                                <td>Server Name</td>
                                <td><%= Environment.MachineName %></td>
                            </tr>
                            <tr>
                                <td>Server IP</td>
                                <td><%= Request.ServerVariables["LOCAL_ADDR"] %></td>
                            </tr>
                            <tr>
                                <td>Operating System Name</td>
                                <td><%= FriendlyOsName() %></td>
                            </tr>
                            <tr>
                                <td>Operating System Version</td>
                                <td><%= Environment.OSVersion.VersionString %></td>
                            </tr>
                            <tr>
                                <td>Server Uptime</td>
                                <td>
                                    <% TimeSpan ts = TimeSpan.FromMilliseconds(Environment.TickCount);
                                       Response.Write(string.Format("{0}days {1}hrs {2}mins", ts.Days, ts.Hours, ts.Minutes)); %>
                                </td>
                            </tr>
                            <tr>
                                <td>Processor Count</td>
                                <td><%= Environment.ProcessorCount %></td>
                            </tr>
                            <tr>
                                <td>Internet Information Services (IIS) Version</td>
                                <td><%= GetIisVersion() %></td>
                            </tr>
                            <tr>
                                <td>IIS Using Integrated Pipeline</td>
                                <td><%= HttpRuntime.UsingIntegratedPipeline %></td>
                            </tr>
                            <tr>
                                <td>.Net Version (Current)</td>
                                <td><%= Environment.Version %></td>
                            </tr>
                            <tr>
                                <td>Current Time</td>
                                <td><%= DateTime.Now.ToString("F") + "<br/><span class=\"text-muted small\">" + TimeZone.CurrentTimeZone.StandardName %></span></td>
                            </tr>
                            <tr>
                                <td>Culture</td>
                                <td><%= CultureInfo.CurrentCulture.Name + " // " + CultureInfo.CurrentCulture.EnglishName %></td>
                            </tr>
                            <tr>
                                <td>UI Culture</td>
                                <td><%= CultureInfo.CurrentUICulture.Name + " // " + CultureInfo.CurrentUICulture.EnglishName %></td>
                            </tr>
                            <tr>
                                <td>System Directory</td>
                                <td><%= Environment.SystemDirectory %></td>
                            </tr>
                            <tr>
                                <td>Current User</td>
                                <td><%= (Environment.UserDomainName + @"\" + Environment.UserName) %></td>
                            </tr>
                    </table>
                </div>

                <a role="link" id="dotnetVersions"></a>
                <div>
                    <h3 class="text-primary">
                        <img src="http://www.microsoft.com/web/media/icons/dotnet-icon.png" alt=".net logo" style="height: 18px;" />.NET<a href="#home" class="pull-right"><span class="glyphicon glyphicon-arrow-up small"></span></a></h3>
                </div>

                <div class="pull-left" style="width: 50%;">

                    <table class="table table-striped">
                        <thead class="text-primary">
                            <tr>
                                <th>Version (derived from filesystem)</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                string[] versions = Directory.GetDirectories(@"C:\Windows\Microsoft.NET\Framework", "v*");
                                string version = "Unknown";

                                for (int i = 0; i < versions.Length; i++)
                                {
                                    int startIndex = versions[i].LastIndexOf("\\") + 2;
                                    version = versions[i].Substring(startIndex, versions[i].Length - startIndex);
                                    if (version.Contains("."))
                                    {
                                        Response.Write(string.Format("<tr><td>{0}</td></tr>", version));
                                    }
                                }
                            %>
                        </tbody>
                    </table>
                </div>

                <div class="pull-right" style="width: 50%;">
                    <table class="table table-striped">
                        <thead class="text-primary">
                            <tr>
                                <th>Version (derived from registry)</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                string[] versions2 = DotNetInstalled().ToArray();
                                string version2 = "Unknown";

                                for (int i = versions2.Length - 1; i >= 0; i--)
                                {
                                    int startIndex = versions2[i].LastIndexOf("\\") + 2;
                                    version2 = versions2[i].Substring(startIndex, versions2[i].Length - startIndex);
                                    if (version2.Contains("."))
                                    {
                                        Response.Write(string.Format("<tr><td>{0}</td></tr>", version2));
                                    }
                                }
                            %>
                        </tbody>
                    </table>
                </div>
                <div class="clearfix"></div>

                <a role="link" id="activeListeners"></a>
                <div>
                    <h3 class="text-primary">Active Listeners<a href="#home" class="pull-right"><span class="glyphicon glyphicon-arrow-up small"></span></a></h3>
                    <table class="table table-striped">
                        <thead class="text-primary">
                            <tr>
                                <th>Address</th>
                                <th>TCP</th>
                                <th>UDP</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                string[] serviceLines = null;
                                if (File.Exists(@"C:\Windows\System32\drivers\etc\services"))
                                {
                                    serviceLines = File.ReadAllLines(@"C:\Windows\System32\drivers\etc\services");
                                }
                                IPGlobalProperties properties = IPGlobalProperties.GetIPGlobalProperties();
                                List<IPEndPointWithType> endpoints = new List<IPEndPointWithType>();
                                foreach (IPEndPoint ep in properties.GetActiveTcpListeners())
                                {
                                    endpoints.Add(new IPEndPointWithType(ep, EndpointType.Tcp));
                                }
                                foreach (IPEndPoint ep in properties.GetActiveUdpListeners())
                                {
                                    endpoints.Add(new IPEndPointWithType(ep, EndpointType.Udp));
                                }
                                endpoints.Sort(CompareEndpoints);

                                foreach (IPEndPointWithType ep in endpoints)
                                {
                                    if (ep.Address.ToString() != "127.0.0.1")
                                    {
                                        string portName = Array.Find(serviceLines, delegate(string s) { return s.Contains(string.Format("{0}/{1}", ep.Port, ep.EndpointType.ToString().ToLowerInvariant())); });
                                        if (portName != null)
                                        {
                                            portName = portName.Substring(0, portName.IndexOf(' '));
                                        }
                                        else
                                        {
                                            portName = string.Empty;
                                        }

                                        if (ep.EndpointType == EndpointType.Tcp)
                                        {
                                            Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td><td></td><td>{2}</td></tr>", ep.Address, ep.Port, portName));
                                        }
                                        else
                                        {
                                            Response.Write(string.Format("<tr><td>{0}</td><td></td><td>{1}</td><td>{2}</td></tr>", ep.Address, ep.Port, portName));
                                        }
                                    }
                                }
                            %>
                    </table>
                </div>

                <a role="link" id="environmentVariables"></a>
                <div>
                    <h3 class="text-primary">Environment Variables<a href="#home" class="pull-right"><span class="glyphicon glyphicon-arrow-up small"></span></a></h3>
                    <table class="table table-striped">
                        <thead class="text-primary">
                            <tr>
                                <th>Property</th>
                                <th>Value</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                foreach (string key in Environment.GetEnvironmentVariables().Keys)
                                {
                                    Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", key, (Environment.GetEnvironmentVariable(key) ?? "").Replace(";", "<br/>")));
                                }
                            %>
                    </table>
                </div>

                <a role="link" id="requestProperties"></a>
                <div>
                    <h3 class="text-primary">Request Properties<a href="#home" class="pull-right"><span class="glyphicon glyphicon-arrow-up small"></span></a></h3>
                    <table class="table table-striped">
                        <thead class="text-primary">
                            <tr>
                                <th>Property</th>
                                <th>Value</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Request.ApplicationPath", Request.ApplicationPath));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Request.AppRelativeCurrentExecutionFilePath", Request.AppRelativeCurrentExecutionFilePath));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Request.CurrentExecutionFilePath", Request.CurrentExecutionFilePath));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Request.FilePath", Request.FilePath));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Request.Path", Request.Path));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Request.HttpMethod", Request.HttpMethod));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Request.IsSecureConnection", Request.IsSecureConnection));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Request.LogonUserIdentity", Request.LogonUserIdentity.Name));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Request.PhysicalApplicationPath", Request.PhysicalApplicationPath));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Request.PhysicalPath", Request.PhysicalPath));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Request.Url", Request.Url));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Request.UserAgent", Request.UserAgent));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Request.UserHostAddress", Request.UserHostAddress));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Request.UserHostName", Request.UserHostName));
                            %>
                    </table>
                </div>

                <a role="link" id="requestHeaders"></a>
                <div>
                    <h3 class="text-primary">Request Headers<a href="#home" class="pull-right"><span class="glyphicon glyphicon-arrow-up small"></span></a></h3>
                    <table class="table table-striped">
                        <thead class="text-primary">
                            <tr>
                                <th>Property</th>
                                <th>Value</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                foreach (string key in Request.Headers.AllKeys)
                                {
                                    Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", key, (Request.Headers[key] ?? "").Trim()));
                                }
                            %>
                    </table>
                </div>


                <% if (HttpRuntime.UsingIntegratedPipeline)
                   {
                %>
                <a role="link" id="responseHeaders"></a>
                <div>
                    <h3 class="text-primary">Response Headers<a href="#home" class="pull-right"><span class="glyphicon glyphicon-arrow-up small"></span></a></h3>
                    <table class="table table-striped">
                        <thead class="text-primary">
                            <tr>
                                <th>Property</th>
                                <th>Value</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                       foreach (string key in Response.Headers.AllKeys)
                       {
                           string headerValue = Response.Headers[key];
                           if (!string.IsNullOrEmpty(headerValue))
                           {
                               Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", key, (Response.Headers[key] ?? "")));
                           }
                       }
                            %>
                    </table>
                </div>
                <% } %>

                <a role="link" id="serverVariables"></a>
                <div>
                    <h3 class="text-primary">Request Server Variables<a href="#home" class="pull-right"><span class="glyphicon glyphicon-arrow-up small"></span></a></h3>
                    <table class="table table-striped">
                        <thead class="text-primary">
                            <tr>
                                <th>Property</th>
                                <th>Value</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                foreach (string key in Request.ServerVariables.AllKeys)
                                {
                                    string headerValue = Request.ServerVariables[key];
                                    if (!string.IsNullOrEmpty(headerValue))
                                    {
                                        Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", key, (Request.ServerVariables[key] ?? "").Trim()));
                                    }
                                }
                            %>
                    </table>
                </div>

                <a role="link" id="connectionStrings"></a>
                <div>
                    <h3 class="text-primary">Connection Strings<a href="#home" class="pull-right"><span class="glyphicon glyphicon-arrow-up small"></span></a></h3>
                    <table class="table table-striped">
                        <thead class="text-primary">
                            <tr>
                                <th>Name</th>
                                <th></th>
                                <th>Connection String</th>
                                <th>Provider</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                foreach (ConnectionStringSettings css in WebConfigurationManager.ConnectionStrings)
                                {
                                    SqlConnectionStringBuilder csb = new SqlConnectionStringBuilder(css.ConnectionString);
                                    csb.ConnectTimeout = 2;
                                    csb.PersistSecurityInfo = true;

                                    bool goodConnection;
                                    try
                                    {
                                        using (SqlConnection c = new SqlConnection(csb.ConnectionString))
                                        {
                                            c.Open();
                                        }

                                        goodConnection = true;
                                    }
                                    catch (Exception ex)
                                    {
                                        goodConnection = false;
                                    }


                                    Response.Write(string.Format("<tr class=\"" + (goodConnection ? "success" : "danger") + "\"><td>{0}</td><td>{3}</td><td>{1}</td><td>{2}</td></tr>", css.Name, css.ConnectionString, css.ProviderName, goodConnection ? "<span class=\"glyphicon glyphicon-ok small\"></span>" : "<span class=\"glyphicon glyphicon-remove small\"></span>"));
                                }
                            %>
                    </table>
                </div>

                <a role="link" id="appSettings"></a>
                <div>
                    <h3 class="text-primary">App Settings<a href="#home" class="pull-right"><span class="glyphicon glyphicon-arrow-up small"></span></a></h3>
                    <table class="table table-striped">
                        <thead class="text-primary">
                            <tr>
                                <th>Name</th>
                                <th>Value</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                foreach (string key in WebConfigurationManager.AppSettings.AllKeys)
                                {
                                    Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", key, WebConfigurationManager.AppSettings[key]));
                                }
                            %>
                    </table>
                </div>

                <a role="link" id="gac"></a>
                <div>
                    <h3 class="text-primary">Global Assembly Cache (GAC)<a href="#home" class="pull-right"><span class="glyphicon glyphicon-arrow-up small"></span></a></h3>
                    <table class="table table-striped">
                        <thead class="text-primary">
                            <tr>
                                <th>Name</th>
                                <th>Version</th>
                                <th>String</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% try
                               {
                                   string windows = Environment.GetEnvironmentVariable("SystemRoot");
                                   if (windows != null)
                                   {
                                       string assembly = Path.Combine(windows, @"assembly");
                                       string[] gacFolders = Directory.GetDirectories(assembly);

                                       List<string> allAssemblies = new List<string>();
                                       foreach (string folder in gacFolders)
                                       {
                                           if (folder.ToLowerInvariant().Contains("\\gac"))
                                           {
                                               string path = Path.Combine(assembly, folder);
                                               if (Directory.Exists(path))
                                               {
                                                   string[] assemblyFolders = Directory.GetDirectories(path);

                                                   if (assemblyFolders.Length <= 0) continue;
                                                   foreach (string assemblyFolder in assemblyFolders)
                                                   {
                                                       if (!allAssemblies.Contains(assemblyFolder))
                                                       {
                                                           allAssemblies.Add(assemblyFolder);
                                                       }
                                                   }
                                               }
                                           }
                                       }
                                       allAssemblies.Sort(CompareStrings);

                                       List<string> assemblyInfo = new List<string>();

                                       foreach (string dll in allAssemblies)
                                       {
                                           FileInfo[] dlls = new DirectoryInfo(dll).GetFiles("*.dll", SearchOption.AllDirectories);
                                           foreach (FileInfo fi in dlls)
                                           {
                                               if (fi.FullName.Contains("__"))
                                               {
                                                   string dir = fi.FullName.Replace(dll + @"\", "");
                                                   dir = dir.Substring(0, dir.IndexOf('\\'));

                                                   assemblyInfo.Add(fi.Name + "~" + dir.Replace("__", "~"));

                                               }
                                           }
                                       }

                                       assemblyInfo.Sort(CompareStrings);

                                       foreach (string dllInfo in assemblyInfo)
                                       {
                                           string[] parts = dllInfo.Split('~');

                                           string dll = parts[0];
                                           string dllVersion = parts[1];
                                           string dllKey = parts[2];

                                           string asmString = string.Format("{2}, Version={0}, PublicKeyToken={1}", dllVersion, dllKey, dll);
                                           Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td><td>{2}</td></tr>", dll.Replace(".dll", string.Empty), dllVersion, asmString));
                                       }

                                   }
                               }
                               catch (NotSupportedException ex)
                               {
                                   Response.Write(ex.Message);
                               }
                            %>
                    </table>
                </div>
            </div>
        </div>
    </div>
    <script type="text/javascript" src="http://code.jquery.com/jquery-latest.min.js"></script>
    <script type="text/javascript" src="http://maxcdn.bootstrapcdn.com/bootstrap/latest/js/bootstrap.min.js"></script>
</body>
</html>
