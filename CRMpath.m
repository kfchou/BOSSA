function path = CRMpath

computername = getenv('computername');
switch computername
    case 'KENNY-PC'
        path = 'C:\Users\Kenny\Dropbox\Sen Lab\CRM corpus\';
    case 'KCHOUYOGA920'
        path = 'C:\Users\kfcho\Dropbox\Sen Lab\CRM corpus\';
    case 'BME-SEN-02'
        path = 'U:\eng_research_hrc_binauralhearinglab\kfchou\toolboxes\CRM\';
    otherwise
        error('Computer not recognised');
end
