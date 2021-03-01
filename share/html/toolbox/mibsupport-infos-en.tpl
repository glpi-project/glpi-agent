    <p class='home'>
    <br/>
    MIB support configuration authorizes you to configure the agent integrated
    MIB support configuration plugin using a flat file in YAML format.<br/>
    This HTTP interface just makes easier the YAML file edition.<br/>
    <br/>
    </p>
    <h2>sysObjectID</h2>
    <p class='home'>
    First you can define your own sysObjectID matches
    and make devices recognized by the agent as <b>NETWORKING</b> or <b>PRINTER</b> devices
    when not recognized by default with the agent known rules.<br/>
    For that you just need to know the matching "sysObjectID" OID and associate it
    to a 'typedef' rule.<br/>
    <br/>
    To find the sysObjectID OID for a given device, you can use the following command,
    updating snmp credentials and targeted ip:<br/>
    <samp>$ snmpwalk -Os -c public -v 2c 192.168.0.1 sysObjectID<br/>
    sysObjectID.0 = OID: enterprises.11.2.3.7.11.17
    </samp><br/>
    <br/>
    </p>
    <h2>Rules</h2>
    <p class='home'>
    For a given device identified by its sysObjectID, you can also enable other rules.
    Each rule can be used to tell the agent which OID can be used to retrieve the 'serial',
    'model', 'manufacturer', 'mac', 'ip', 'firmware' or 'firmwaredate'.<br>
    For that, after you have created a new rule, just associate it to the corresponding sysObjectID match.<br/>
    <br/>
    </p>
    <h2>MIBSupport</h2>
    <p class='home'>
    When the agent recognizes a device, it also checks the
    <a href="https://tools.ietf.org/html/rfc3418#page-6" target='_blank'>sysORTable</a> SNMP table
    for known <b>sysORID sysOREntry</b> as OID entries. As these entries identify a MIB support,
    you can use MIB support configuration to associate rules to apply for a well-known MIB.<br/>
    <br/>
    To check if a device exposes such sysORID entries OIDs, you can use the following command,
    updating snmp credentials and targeted ip:<br/>
    <samp>$ snmpwalk -Os -c public -v 2c 192.168.0.1 sysORID<br/>
    sysORID.1 = OID: snmpMIB<br/>
    sysORID.2 = OID: vacmBasicGroup<br/>
    sysORID.3 = OID: tcpMIB<br/>
    ...
    </samp><br/>
    <br/>
    When possible you should better create MIB support configuration rules as the ruleset
    can seemlessly be applied on more devices than just on sysObjectID.<br/>
    <br/>
    </p>
    <h2>Aliases</h2>
    <p class='home'>
    To simplify OID management, you can uses aliases.
    Use it as a dictionary of alias resolving to numeric OID.<br>
    For your convenience, 'iso', 'private', 'enterprises' and 'mib-2' are natively
    supported by the agent and you don't need to add them in your dictionary.<br/>
    <br/>
    <h2>First step...</h2>
    <p class='home'>
    The first step to create your YAML file would be to add 2 important rules:<br/>
    </p>
    <ul class='home'>
      <li>Go to "Rules" tab and click on "Add a new rule"</li>
      <li>Set rule 'name' as "networking"</li>
      <li>Select rule 'type' to be "typedef"</li>
      <li>Set rule 'value' to "NETWORKING"</li>
      <li>Set rule 'value type' to "raw"</li>
      <li>Set the rule 'description' to something like "Recognize device as a networking device"</li>
      <li>Click on "Add"</li>
    </ul>
    <p class='home'>
    You now have your first 'networking' rule you would like to associate with some sysObjectID matches.<br/>
    Repeat the same steps to create a 'printer' rule:<br/>
    </p>
    <ul class='home'>
      <li>setting rule 'name' as "printer",</li>
      <li>always selecting rule 'type' as "typedef",</li>
      <li>setting rule 'value' to "PRINTER",</li>
      <li>set rule 'value type' to "raw",</li>
      <li>setting the rule 'description' to something like "Recognize device as a printer",</li>
      <li>and clicking on "Add".</li>
    </ul>
    <p class='home'>
    In fact, this is what is done when your configured YAML file doesn't exist.<br/>
    </p>
