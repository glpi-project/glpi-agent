  <div id="footer">
    <div class='footer-row'>
      <div class='footer-cell'>
        <div class="left">{_("DeviceID").":"}</div>
        <div class="left" style='display: {$agentid ? "" : "none"}'>{_("AgentID").":"}</div>
      </div>
      <div class='footer-cell'>
        <div class="left">{$deviceid}</div>
        <div class="left" style='display: {$agentid ? "" : "none"}'>{$agentid}</div>
      </div>
      <div class='grow'></div>
      <div class='footer-cell'>
        <div class="right"><a href="{$url}">{$agent}</a></div>
        <div class="right">{$plugin}</div>
      </div>
    </div>
  </div>
</body>
</html>
