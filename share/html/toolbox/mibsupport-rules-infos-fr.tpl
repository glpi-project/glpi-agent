      Voici la liste des règles connues.<br/>
      Le nom de règle doit être unique, débuter par une lettre ou un chiffre et ne contenir que des lettres, chiffres, tirets, points ou caractères de soulignement.<br/>
      Le type peut être un <b>typedef</b> définissant le type de l'équipement, essentiellement 'NETWORKING'
      ou 'PRINTER'. Cela peut être aussi <b>serial</b>, <b>model</b>, <b>manufacturer</b>, <b>mac</b>,
      <b>ip</b>, <b>firmware</b> ou <b>firmwaredate</b> pour indiquer à l'agent quel OID doit être utilisé pour
      retrouver l'information correspondante.<br/>
      Le type de la valeur doit toujours être <b>raw</b> pour les règles <b>typedef</b>,
      sinon cela peut être utilisé dans certain cas pour normaliser la sortie en tant qu'adresse MAC, numéro de série ou juste une chaine de caractères.<br/>
