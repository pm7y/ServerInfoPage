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
<%@ Import Namespace="System.Diagnostics" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Net.NetworkInformation" %>
<%@ Import Namespace="System.Runtime.InteropServices" %>
<%@ Import Namespace="Microsoft.Win32" %>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="">
    <meta name="author" content="">
    <link rel="stylesheet" type="text/css" href="http://maxcdn.bootstrapcdn.com/bootstrap/latest/css/bootstrap.min.css" />
    <link rel="stylesheet" type="text/css" href="http://maxcdn.bootstrapcdn.com/font-awesome/latest/css/font-awesome.min.css" />
    <title>ASP.NET Host Script</title>

    <script runat="server">      

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

    public string FriendlyOSName()
    {
        string productName = HKLM_GetString(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion", "ProductName");
        string csdVersion = HKLM_GetString(@"SOFTWARE\Microsoft\Windows NT\CurrentVersion", "CSDVersion");
        if (productName != string.Empty)
        {
            return (productName.StartsWith("Microsoft") ? string.Empty : "Microsoft ") + productName + (csdVersion != string.Empty ? " " + csdVersion : string.Empty);
        }
        return string.Empty;
    }


    public Version GetIISVersion()
    {
        using (Microsoft.Win32.RegistryKey componentsKey = Microsoft.Win32.Registry.LocalMachine.OpenSubKey(@"Software\Microsoft\InetStp", false))
        {
            if (componentsKey != null)
            {
                int majorVersion = (int) componentsKey.GetValue("MajorVersion", -1);
                int minorVersion = (int) componentsKey.GetValue("MinorVersion", -1);

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
<body role="document">
    <div class="container" role="main">
        <div class="row">
            <div class="col-md-12">
                <h1><%= ( Environment.MachineName + " (" + Request.ServerVariables["LOCAL_ADDR"] +")") %></h1>
            </div>
        </div>
        <div class="row">
            <div class="col-md-12">
                <h3>Essential Information about <%=Environment.MachineName%></h3>
                <div class="col-md-6">
                    <table class="table table-condensed">
                        <tbody>
                            <tr>
                                <td>Server Name</td>
                                <td><%=Environment.MachineName %></td>
                            </tr>
                            <tr>
                                <td>Server IP</td>
                                <td><%=Request.ServerVariables["LOCAL_ADDR"]%></td>
                            </tr>
                            <tr>
                                <td>Operating System</td>
                                <td><%=FriendlyOSName()%></td>
                            </tr>
                            <tr>
                                <td>Processor Count</td>
                                <td><%=Environment.ProcessorCount%></td>
                            </tr>
                            <tr>
                                <td>Internet Information Services (IIS) Version</td>
                                <td><%=GetIISVersion()%></td>
                            </tr>
                            <tr>
                                <td>.Net Version (Current)</td>
                                <td><%=Environment.Version%></td>
                            </tr>
<%--                            <tr>
                                <td>.Net Version (Highest)</td>
                                <td><%=Environment.Version%></td>
                            </tr>--%>
                    </table>
                </div>
            </div>
        </div>

        <div class="row">
            <div class="col-md-12">
                <h3>.NET Versions Installed</h3>
                <div class="col-md-6">
                    <table class="table table-condensed">
                        <thead>
                            <tr>
                                <th>Installed Version (derived from filesystem)</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                string[] versions = Directory.GetDirectories(@"C:\Windows\Microsoft.NET\Framework", "v*");
                                string version = "Unknown";

                                for (int i = versions.Length - 1; i >= 0; i--)
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

                <div class="col-md-6">
                    <table class="table table-condensed">
                        <thead>
                            <tr>
                                <th>Installed Version (derived from registry)</th>
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
            </div>
            <div class="col-md-12">
                <h3>Active TCP Listeners</h3>
                <div class="col-md-6">
                    <table class="table table-condensed">
                        <thead>
                            <tr>
                                <th>Address</th>
                                <th>Port</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%  
                                IPGlobalProperties properties = IPGlobalProperties.GetIPGlobalProperties();
                                IPEndPoint[] endPoints = properties.GetActiveTcpListeners();
                                foreach (System.Net.IPEndPoint e in endPoints)
                                {
                                    if (!e.Address.IsIPv6LinkLocal && !e.Address.IsIPv6Multicast && !e.Address.IsIPv6SiteLocal)
                                    {
                                        Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", e.Address, e.Port));
                                    }
                                }
                            %>
                    </table>
                </div>
            </div>

            <div class="col-md-12">
                <h3>Environment</h3>
                <div class="col-md-12">
                    <table class="table table-condensed">
                        <thead>
                            <tr>
                                <th>Property</th>
                                <th>Value</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%  
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Environment.MachineName", Environment.MachineName));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Environment.OSVersion.VersionString", Environment.OSVersion.VersionString));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Environment.ProcessorCount", Environment.ProcessorCount));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Environment.SystemDirectory", Environment.SystemDirectory));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Environment.UserDomainName", Environment.UserDomainName));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Environment.UserName", Environment.UserName));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Environment.Version", Environment.Version.ToString()));
                                foreach (string key in Environment.GetEnvironmentVariables().Keys)
                                {
                                    Response.Write(string.Format("<tr><td>Environment.GetEnvironmentVariable(\"{0}\")</td><td>{1}</td></tr>", key, (Environment.GetEnvironmentVariable(key) ?? "").Replace(";", "<br/>")));
                                }
                            %>
                    </table>
                </div>
            </div>

            <div class="col-md-12">
                <h3>Request</h3>
                <div class="col-md-12">
                    <table class="table table-condensed">
                        <thead>
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
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Request.PhysicalApplicationPath", Request.PhysicalApplicationPath));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Request.Url", Request.Url.ToString()));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Request.UserAgent", Request.UserAgent));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Request.UserHostAddress", Request.UserHostAddress));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "Request.UserHostName", Request.UserHostName));
                                Response.Write("<tr><th colspan=\"2\">Request.Headers</th></tr>");
                                foreach (string key in Request.Headers.AllKeys)
                                {
                                    Response.Write(string.Format("<tr><td>Request.Headers[\"{0}\"]</td><td>{1}</td></tr>", key, (Request.Headers[key] ?? "").Trim()));
                                }
                                Response.Write("<tr><th colspan=\"2\">Request.ServerVariables</th></tr>");
                                foreach (string key in Request.ServerVariables.AllKeys)
                                {
                                    string headerValue = Request.ServerVariables[key];
                                    if (!string.IsNullOrEmpty(headerValue))
                                    {
                                        Response.Write(string.Format("<tr><td>Request.ServerVariables[\"{0}\"]</td><td>{1}</td></tr>", key, (Request.ServerVariables[key] ?? "").Trim()));
                                    }
                                }
                            %>
                    </table>
                </div>
            </div>

            <% if (HttpRuntime.UsingIntegratedPipeline)
               {
            %>
            <div class="col-md-12">
                <h3>Response</h3>
                <div class="col-md-12">
                    <table class="table table-condensed">
                        <thead>
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
                           Response.Write(string.Format("<tr><td>Response.Headers[\"{0}\"]</td><td>{1}</td></tr>", key, (Response.Headers[key] ?? "")));
                       }
                   }
                            %>
                    </table>
                </div>
            </div>
            <% } %>

            <div class="col-md-12">
                <h3>IIS</h3>
                <div class="col-md-12">
                    <table class="table table-condensed">
                        <thead>
                            <tr>
                                <th>Property</th>
                                <th>Value</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%  
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "IIS Version", GetIISVersion()));
                                Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", "HttpRuntime.UsingIntegratedPipeline", HttpRuntime.UsingIntegratedPipeline));
                            %>
                    </table>
                </div>
            </div>

            <div class="col-md-12">
                <h3>Global Assembly Cache (GAC)</h3>
                <div class="col-md-12">
                    <table class="table table-condensed">
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
                                                       string dllName = assemblyFolder.Replace(path, "").Replace(@"\", "") + ".dll";
                                                       if (!allAssemblies.Contains(dllName))
                                                       {
                                                           allAssemblies.Add(dllName);
                                                       }
                                                   }
                                               }
                                           }
                                       }
                                       allAssemblies.Sort();

                                       foreach (string dll in allAssemblies)
                                       {
                                           Response.Write(string.Format("<tr><td>{0}</td></tr>", dll));
                                       }
                                   }
                               }
                               catch (NotSupportedException ex) { Response.Write(ex.Message); }
                            %>
                    </table>
                </div>
            </div>

        </div>
    </div>
    <script type="text/javascript" src="http://maxcdn.bootstrapcdn.com/bootstrap/latest/js/bootstrap.min.js"></script>
</body>
</html>
