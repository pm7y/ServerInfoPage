using System;
using System.Collections.Generic;
using Microsoft.Win32;

namespace ServerInfoPage
{
    /// <summary>
    /// 
    /// </summary>
    /// <remarks></remarks>
    public partial class _Default : System.Web.UI.Page
    {
        /// <summary>
        /// Handles the Load event of the Page control.
        /// </summary>
        /// <param name="sender">The source of the event.</param>
        /// <param name="e">The <see cref="System.EventArgs"/> instance containing the event data.</param>
        /// <remarks></remarks>
        protected void Page_Load(object sender, EventArgs e)
        {
            Response.Write("<table><tr><td>Installed .NET Versions</td></tr>");
            foreach (string key in DotNetInstalled())
            {
                if (!string.IsNullOrEmpty(key))
                {
                    Response.Write(string.Format("<tr><td>{0}</td></tr>", key));
                }
            }
            Response.Write("</table>");


            Response.Write("<br/><br/>");


            Response.Write("<table><tr><td colspan=\"2\">Request Server Variables</td></tr><tr><td>Key</td><td>Value</td></tr>");
            foreach (string key in this.Request.ServerVariables.AllKeys)
            {
                string val = this.Request.ServerVariables[key];
                if (!string.IsNullOrEmpty(val))
                {
                    Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", key, val));
                }
            }
            Response.Write("</table>");


            Response.Write("<br/><br/>");


            Response.Write("<table><tr><td colspan=\"2\">Request Headers</td></tr><tr><td>Key</td><td>Value</td></tr>");
            foreach (string key in this.Request.Headers.AllKeys)
            {
                string val = this.Request.Headers[key];
                if (!string.IsNullOrEmpty(val))
                {
                    Response.Write(string.Format("<tr><td>{0}</td><td>{1}</td></tr>", key, val));
                }
            }
            Response.Write("</table>");
        }

        /// <summary>
        /// Dots the net installed.
        /// </summary>
        /// <returns></returns>
        /// <remarks></remarks>
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
    }
}
