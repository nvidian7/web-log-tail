<%@ page import="java.io.RandomAccessFile" %>
<%@ page import="java.io.FileNotFoundException" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.io.InputStreamReader" %>
<%@ page import="java.io.BufferedReader" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%
    final String LOG_FILE_PATH = "/where/are/logs/"; // absolute path ( ex. /home/styx/logs/ )
    final String PASSWORD = "input your password here what you want"; 
    final int UNAUTH_RESULT_CODE = 403; // invalid password from login-page or directly access on this page -> HTTP 403
    
    String securityKey = request.getParameter("security_key");

    if(securityKey == null || !securityKey.equals(PASSWORD)) {
        response.sendError(UNAUTH_RESULT_CODE);
    }
    
    String fileName = request.getParameter("log_filename") == null ? "" : request.getParameter("log_filename");

    if ("".equals(fileName.trim()) == false) {

        fileName = LOG_FILE_PATH + fileName.trim().replaceAll("\\.\\.", "");

        long preEndPoint = request.getParameter("preEndPoint") == null ? 0 : Long.parseLong(request.getParameter("preEndPoint") + "");

        StringBuilder log = new StringBuilder();
        long startPoint = 0;
        long endPoint = 0;

        RandomAccessFile file = null;

        try {
            file = new RandomAccessFile(fileName, "r");
            endPoint = file.length();

            startPoint = preEndPoint > 0 ?
                            preEndPoint : endPoint < 2000 ?
                            0 : endPoint - 2000;

            file.seek(startPoint);

            String str;
            while ((str = file.readLine()) != null) {
                log.append(str);
                log.append("\n");
                endPoint = file.getFilePointer();
                file.seek(endPoint);
            }

        } catch (FileNotFoundException fnfe) {
            log.append("File does not exist.");
            fnfe.printStackTrace();
        } catch (Exception e) {
            log.append("Sorry. An error has occurred.");
            e.printStackTrace();
        } finally {
            try {file.close();} catch (Exception e) {}
        }

        out.print("{\"endPoint\":\"" + endPoint + "\", \"log\":\"" + URLEncoder.encode(new String(log.toString().getBytes("ISO-8859-1"),"UTF-8"), "UTF-8").replaceAll("\\+", "%20") + "\"}");

    } else {

        List<String> fileList = new ArrayList<String>();
        String line = null;
        BufferedReader br = null;
        Process ps = null;
        try {
            Runtime rt = Runtime.getRuntime();
            ps = rt.exec(new String[]{"/bin/sh", "-c", "find "+ LOG_FILE_PATH + " -maxdepth 1 -type f -exec basename {} \\; | sort"});
            br = new BufferedReader(new InputStreamReader(ps.getInputStream()));

            while( (line = br.readLine()) != null ) {
                fileList.add(line);
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try { br.close(); } catch(Exception e) {}
        }
%>
<html>
<head>
    <title></title>
    <script src="http://code.jquery.com/jquery-1.11.2.min.js"></script>
    <style type="text/css">
        * {
            margin: 0;
            padding: 0;
        }
        #top {
            position:relative;
            width: 1000px;
        }
        #header {
            top: 0;
            left: 0px;
            width: 100%;
            padding: 5px 10px 10px 10px;
        }
        #console {
            width: 890;
            background-color: #111111;
            color:lightgray;
            font-size: 11px;
            margin: 5px 0px 0px 10px;
        }
        #runningFlag {
            color: red;
        }
        #toolbar {
            display: inline-block;
            float: left;
            width: 720px;
            height: 30px;
            padding: 1px 0px 0px 10px;
        }
        #buttons {
            display: inline-block;
            height:30px;
            width:200px;
        }
        #buttons input[type="button"]{
            background: #2B3856;
            border: none;
            padding: 0px 0px 0px 0px;
            font-weight: bold;
            border-bottom: 4px solid #BCC6CC;
            border-radius: 0px;
            color: #DDDDDD;
            width:80px;
            height:20px;
        }
        #buttons input[type="button"]:hover{
            background: #4863A0;
            color:#fff;
        }
        #status {
            width:890px;
            padding: 0px 0px 0px 10px;
        }
        #status span{
            background: #F3F3F3;
            display: block;
            padding: 3px;
            margin:5px 0px 0px 0px;
            text-align: center;
            font-weight: bold;
            color: #FF5050;
            font-family: Arial, Helvetica, sans-serif;
            font-size: 14px;
        }

    </style>
    <script type="text/javascript">
$(document).ready(function() {
        resizeContent();
    });
    $(window).resize(function() {
        resizeContent();
    });

    function resizeContent() {
        var windowHeight = $(window).height();
        var topHeight = $("#top").height()+10;
        $('#console').css({'height':(windowHeight-topHeight)+'px'});
    }
        var endPoint = 0;
        var tailFlag = false;
        var fileName;
        var consoleLog;
        var grep;
        var grepV;
        var pattern;
        var patternV;
        var runningFlag;
        var match;
        var securityKey;
        $(document).ready(function() {
            consoleLog = $('#console');
            runningFlag = $('#runningFlag');

            function startTail() {
                runningFlag.html('running...');
                fileName = $('#fileName').val();
                securityKey = $('#securityKey').val();
                grep = $.trim($('#grep').val());
                grepV = $.trim($('#grepV').val());
                pattern = new RegExp('.*'+grep+'.*\\n', 'g');
                patternV = new RegExp('.*'+grepV+'.*\\n', 'g');
                function requestLog() {
                    if (tailFlag) {
                        $.ajax({
                            type : 'POST',
                            url : 'logTail.jsp',   // #### Caution: The name of the source file
                            dataType : 'json',
                            data : {
                                'log_filename' : fileName,
                                'preEndPoint' : endPoint,
                                'security_key' : securityKey

                            },
                            success : function(data) {
                                endPoint = data.endPoint == false ? 0 : data.endPoint;
                                logdata = decodeURIComponent(data.log);
                                if (grep != false) {
                                    match = logdata.match(pattern);
                                    logdata = match ? match.join('') : '';
                                }
                                if (grepV != false) {
                                    logdata = logdata.replace(patternV, '');
                                }
                                consoleLog.val(consoleLog.val() + logdata);
                                consoleLog.scrollTop(consoleLog.prop('scrollHeight'));

                                setTimeout(requestLog, 1000);
                            }
                        });
                    }
                }
                requestLog();
            }
            $('#Start').on('click', function() {tailFlag = true; startTail();});
            $('#Stop').on('click', function() {
                tailFlag = false;
                runningFlag.html('stopped...');
            });
            $('#fileName').change(function() {
                tailFlag = false;
                endPoint = 0;
                runningFlag.html('stopped...');
            });
        });
    </script>
</head>
<body>
<div id="top" style="height:100px">
<div id="header">
    <h2>Styx's logfile web tail</h2>
</div>
<div id="toolbar">
    tail -f
    <select id="fileName">
<%  for (String file : fileList) {  %>
        <option value="<%=file%>"><%=file%></option>
<%  }   %>
    </select>
        | grep <input id="grep" type="text" />
        | grep -v <input id="grepV" type="text" />
        |
</div>
<div id="buttons">
        <input id="Start" type="button" value="Start"/>&nbsp;
        <input id="Stop" type="button" value="Stop" style=""/>
        <input type="hidden" id="securityKey" value="<%=securityKey%>"/>
</div>
<div id="status">
    <span id="runningFlag">stopped...</span>
</div>
</div>
<textarea id="console"></textarea>
</body>
</html>
<%
    }
%>
