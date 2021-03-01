    <p class='home'>
    <br/>
    La configuration du support MIB vous autorise à paramétrer le module complémentaire
    intégré à l'agent apportant le support MIB en utilisant un fichier plat au format YAML.<br/>
    Cette interface HTTP permet juste de simplifier l'édition du fichier YAML.<br/>
    <br/>
    </p>
    <h2>sysObjectID</h2>
    <p class='home'>
    Premièrement, vous pouvez définir vos propres correspondances sur le sysObjectID et
    faire que les équipements soit reconnus par l'agent comme type <b>NETWORKING</b> ou <b>PRINTER</b>
    quand les règles connues de l'agent ne lui permettent pas de reconnaître le type.<br/>
    Pour cela, vous avez juste à connaître l'OID "sysObjectID" et l'associer à une règle
    définissant le 'typedef'.<br/>
    <br/>
    Pour trouver l'OID sysObjectID d'un équipement donné, vous pouvez utiliser la commande suivante,
    en adaptant les identifiants SNMP et l'ip cible :<br/>
    <samp>$ snmpwalk -Os -c public -v 2c 192.168.0.1 sysObjectID<br/>
    sysObjectID.0 = OID: enterprises.11.2.3.7.11.17
    </samp><br/>
    <br/>
    </p>
    <h2>Règles</h2>
    <p class='home'>
    Pour un équipement donné identifiée par son sysObjectID, vous pouvez aussi activer d'autres règles.
    Chaque règle peut être utilisée pour indiquer à l'agent quel OID utiliser pour retrouver le 'serial',
    'model', 'manufacturer', 'mac', 'ip', 'firmware' ou 'firmwaredate'.<br>
    Pour cela, après avoir créer une nouvelle règle, associez-la simplement avec la correspondance de sysObjectID.<br/>
    <br/>
    </p>
    <h2>Support de MIB</h2>
    <p class='home'>
    Quand l'agent découvres un équipement, il vérifie aussi la table SNMP
    <a href="https://tools.ietf.org/html/rfc3418#page-6" target='_blank'>sysORTable</a>
    pour des entrées <b>sysORID sysOREntry</b> connues. Comme ces entrées identifient un support de MIB,
    vous pouvez utiliser la configuration du support de MIB pour associer des règles qui s'appliqueront pour des MIBs connues.<br/>
    <br/>
    Pour vérifier si un équipement expose de telles OIDs comme sysORID, vous pouvez utiliser la commande suivante :<br/>
    <samp>$ snmpwalk -Os -c public -v 2c 192.168.0.1 sysORID<br/>
    sysORID.1 = OID: snmpMIB<br/>
    sysORID.2 = OID: vacmBasicGroup<br/>
    sysORID.3 = OID: tcpMIB<br/>
    ...
    </samp><br/>
    <br/>
    Quand c'est possible, vous devriez plutôt utiliser des règles de support de MIB parce que
    les jeux de règles associé s'appliquera automatiquement à plus d'équipement qu'une simple correspondance de sysObjectID.<br/>
    <br/>
    </p>
    <h2>Alias</h2>
    <p class='home'>
    Pour simplifier la gestion des OIDs, vous pouvez utiliser des alias.
    Utilisez ça comme un dictionnaire de résolution d'alias en OID numérique.<br>
    Pour votre confort, les alias 'iso', 'private', 'enterprises' et 'mib-2' sont déjà
    supportés par l'agent et vous n'avez donc pas besoin de les ajouter à votre dictionnaire.<br/>
    <br/>
    <h2>Première étape...</h2>
    <p class='home'>
    La premère étape pour créer votre fichier YAML serait d'ajouter 2 règles importantes :<br/>
    </p>
    <ul class='home'>
      <li>Commencez par cliquer sur "Ajouter une nouvelle règle" dans l'onglet "Règles"</li>
      <li>Utilisez le nom de règle "networking"</li>
      <li>Sélectionnez le type de règle "typedef"</li>
      <li>Définissez la valeur de règle à "NETWORKING"</li>
      <li>Laissez le type de valeur à "raw"</li>
      <li>Ajouter une description de règle qui pourrait être "Reconnaître l'équipement comme un équipement réseau"</li>
      <li>Cliquez sur "Ajouter"</li>
    </ul>
    <p class='home'>
    Vous avez maintenant votre première règle 'networking' que vous voudriez associer à quelques correspondances de sysObjectID.<br/>
    Répétez les mêmes étapes pour créer une règle 'printer' :<br/>
    </p>
    <ul class='home'>
      <li>en définissant le nom à "printer"</li>
      <li>en sélectionnant encore le type de règle "typedef"</li>
      <li>en définissant la valeur à "PRINTER"</li>
      <li>en laissant le type de valeur à "raw"</li>
      <li>en ajoutant une description du genre "Reconnaître un équipement comme étant une imprimante"</li>
      <li>et en finissant par cliquer sur "Ajouter"</li>
    </ul>
    <p class='home'>
    En fait, c'est déjà ce que devrait être par l'interface quand votre fichier YAML n'existe pas.<br/>
    </p>
