<#
examples:
1) filename.ps1 all
Print all matches

2)filename.ps1 LLD
Json output for zabbix lld 

3)filename.ps1 "my unique task name " 3
get size file MB task "my unique task name " . accepts index values in the range 0..3
#>

# get Installation directory for x64 bit OS. OS x32 bit OS not tested !!!!!!!
# проверенно на 64 битной ос, 32 битн ОС не проверенна!!!!!!!!
cls
$InstalDir=(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\CobianSoft\Cobian Backup 11\' | Select-Object -ExpandProperty 'Installation directory')
#logs file today dir
#получение полного пути сегодняшнего файла
$filename= $InstalDir + "Logs\log "+ (get-date -Format yyyy-MM-dd ).ToString()+".txt"
#regular expression for find end task log message. Modify this is a regexp. test regexp -  https://regex101.com/
#regexp for langue RUSSIAN text log char
# регулярное выражение. Изменить под себя, проверить на сайте https://regex101.com/
$RegexpTaskEnd = 'Задание "' + $args[0] + '" завершено. Ошибок:\s(\d+), обработано файлов:\s+(\d+),\s+скопировано\s+файлов:\s+(\d+),\s+общий\sразмер:\s(\d+,\d+)\s+(\w+[GB|MB])'

#switch LLD or ALL or Zabbix.items
switch -regex ($args[0])
  {

  # zabbix LLD get 
  #find LLD zabbix Name shedule.
  # поиск низкоуровневого обнаружения
"^[l,L][l,L][d,D]$" {
                          $mainlist = $InstalDir + 'DB\MainList.lst'
                      
                          @{
                          'data' = @( ( Get-Content $mainlist | Select-String ('^Name=(.*)$')) -replace("Name=","") | % {
                                          @{
                                          '{#NAME}' = $_}
                                      }
                                      )
                          } | ConvertTo-Json
                        } 

# all matches print. For DEBUG 
# вывести все совпадения. Для отладки.
# 
# ----------------------------------------------------------------------------
"^[a,A][l,L][l,L]$"{
                      if ((Test-Path $filename) )
                        {
                            #regexp find match from log file.
                            #вывести все совпадения
                           Get-Content $filename |Select-String ($RegexpTaskEnd -replace($args[0],".*")); #-replace($args[0],".*") - find all matches name -eq '.*'
                        }
                    }
          # ----------------------------------------------------------------------------


# zabbix get data for items
# zabbix получение данных 
"[B,b]ackup\s"{
        <#
              check args[1] -eq range 0..3, else exit script!
             
              indexes:
              0 - errors count 
              1 - checked files count
              2 - copy files count 
              3 - size files count(convert GB to Mb)
             Проверка args[1] принадлежности к диапазону 0..3, иначе выход из скрипта!
              Индексы:
              0 - количество ошибок
              1 - проверенно файлов
              2 - скопированно файлов
              3 - объем данных(конвертация GB to Mb)

         #>
            if ( ([regex]::Match( $args[1], '^[0-3]$')).success -eq $true) 
            {
                if ((Test-Path $filename) )
                    {
                        #regexp find match from log file.
                        $matches = Get-Content $filename |Select-String $RegexpTaskEnd
                        #$matches.coun > 0. else exit, matches not found, exit !!!
                        #$matches.coun > 0 иначе выход, регулярное выражение не найдено

                        if ($matches.count -gt 0)
                        {#create array object
                         #создаем массив 
                         $out1 = New-Object System.Collections.Generic.List[System.Object]
                         foreach ($match in $matches)
                                    { #check size Gigabyte and convert to Megabyte
                                      # проверка объема гигабайтов и конвертация в мегабайты
                                     if ($match.Matches.groups[5].value -eq "GB")
                                        {
                                           for ($i=1; $i -le 3; $i++)
                                                { 
                                                 $out1.Add(($match.Matches.groups[$i].value))
                                                }
                           
                                                $out1.Add([double]($match.Matches.Groups.Value[4]).Replace(",",".")*1024) #Gigabyte to megabytes converts #гигабайты в мегабайты
                                            }else{ 
                                                  #$match.Matches.groups[6].value  - is value a MEGABYTES
                                                  #$match.Matches.groups[6].value  - данные в мегабайтах
                                                  for ($i=1; $i -le 4; $i++) 
                                                        {
                                                        $out1.Add(($match.Matches.groups[$i].value))
                                                        }
                                                  }
                                    }
                        } else {
                                #exit not matches, $matches.count < 1; 
                                #выход не найдена регулярка, $matches.count < 1;
                                echo "0"
                                exit;
                               }
                               
                               cls
                               #transforms Zabbix requirements for a data type [float]
                               #трансформация для Zabbix , под нужный тип данных [дробный]
                        echo (($out1.item($args[1]) -replace(",","."))); 
                        exit;
                    } 
                    else {
                         #print "0" so that Zabbix does not swear at an empty value as a string.
                         #вывести "0" чтоб Zabbix Не ругался на пустое значение как строка.
                         echo "0"
                         exit;
                         }

              } else {
                      # args[1] -ne range [0..3], exit script. echo -1 for DEBUG
                      # args[1] не принадлежит диапазону [0..3], выход из скрипта. Вывести -1 для отладки.
                      echo "index not found"
                      exit;
                      }

            }
  }
