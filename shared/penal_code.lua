PenalCode = {
    {
        category = {
            cs = 'Dopravní přestupky',
            en = 'Traffic Violations',
            de = 'Verkehrsverstöße'
        },
        items = {
            {
                id = 't_speeding_1',
                title = {
                    cs = 'Překročení rychlosti (nízké)',
                    en = 'Speeding (Minor)',
                    de = 'Geschwindigkeitsüberschreitung (gering)'
                },
                fine = 500,
                prison = 0
            },
            {
                id = 't_speeding_2',
                title = {
                    cs = 'Překročení rychlosti (vysoké)',
                    en = 'Speeding (Major)',
                    de = 'Geschwindigkeitsüberschreitung (schwer)'
                },
                fine = 1500,
                prison = 0
            },
            {
                id = 't_red_light',
                title = {
                    cs = 'Jízda na červenou / nerespektování značení',
                    en = 'Running Red Light / Failure to Obey Traffic Signs',
                    de = 'Überfahren einer roten Ampel / Missachtung von Verkehrszeichen'
                },
                fine = 800,
                prison = 0
            },
            {
                id = 't_wrong_way',
                title = {
                    cs = 'Jízda v protisměru',
                    en = 'Driving on Wrong Side of Road',
                    de = 'Fahren auf der falschen Straßenseite (Geisterfahrer)'
                },
                fine = 1200,
                prison = 0
            },
            {
                id = 't_reckless',
                title = {
                    cs = 'Nebezpečná a bezohledná jízda',
                    en = 'Reckless & Dangerous Driving',
                    de = 'Rücksichtsloses und gefährliches Fahren'
                },
                fine = 2500,
                prison = 5
            },
            {
                id = 't_hit_and_run',
                title = {
                    cs = 'Ujetí od dopravní nehody',
                    en = 'Hit and Run (Leaving Scene of Accident)',
                    de = 'Unerlaubtes Entfernen vom Unfallort (Fahrerflucht)'
                },
                fine = 3500,
                prison = 10
            },
            {
                id = 't_no_license',
                title = {
                    cs = 'Řízení bez řidičského oprávnění',
                    en = 'Driving Without Valid License',
                    de = 'Fahren ohne Fahrerlaubnis'
                },
                fine = 2000,
                prison = 5
            },
            {
                id = 't_dui',
                title = {
                    cs = 'Řízení pod vlivem alkoholu / návykových látek (DUI)',
                    en = 'Driving Under the Influence (DUI)',
                    de = 'Fahren unter Alkoholeinfluss / Drogen (DUI)'
                },
                fine = 4000,
                prison = 10
            }
        }
    },
    {
        category = {
            cs = 'Veřejný pořádek',
            en = 'Public Order',
            de = 'Öffentliche Ordnung'
        },
        items = {
            {
                id = 'p_disobey',
                title = {
                    cs = 'Neuposlechnutí výzvy veřejného činitele',
                    en = 'Failure to Comply with Peace Officer',
                    de = 'Widersetzen polizeilicher Anordnungen'
                },
                fine = 1500,
                prison = 5
            },
            {
                id = 'p_insult',
                title = {
                    cs = 'Urážka nebo vyhrožování veřejnému činiteli',
                    en = 'Contempt of / Threats to Peace Officer',
                    de = 'Beleidigung oder Bedrohung von Polizeibeamten'
                },
                fine = 2000,
                prison = 5
            },
            {
                id = 'p_trespassing',
                title = {
                    cs = 'Neoprávněný vstup na cizí pozemek / vládní objekt',
                    en = 'Criminal Trespassing / Restricted Government Property',
                    de = 'Hausfriedensbruch / Unbefugtes Betreten von Sperrgebieten'
                },
                fine = 3000,
                prison = 10
            },
            {
                id = 'p_disorderly',
                title = {
                    cs = 'Výtržnictví a rušení veřejného pořádku',
                    en = 'Disorderly Conduct & Breach of Peace',
                    de = 'Erregung öffentlichen Ärgernisses & Ruhestörung'
                },
                fine = 1000,
                prison = 0
            },
            {
                id = 'p_evading',
                title = {
                    cs = 'Útěk před policií / pronásledování',
                    en = 'Evading Police (Foot or Vehicle Pursuit)',
                    de = 'Flucht vor der Polizei (Verfolgung)'
                },
                fine = 3000,
                prison = 10
            },
            {
                id = 'p_mask',
                title = {
                    cs = 'Zahalování tváře na veřejném prostranství',
                    en = 'Concealing Identity in Public Space',
                    de = 'Vermummungsverbot im öffentlichen Raum'
                },
                fine = 800,
                prison = 0
            }
        }
    },
    {
        category = {
            cs = 'Majetková trestná činnost',
            en = 'Property Crimes',
            de = 'Eigentumsdelikte'
        },
        items = {
            {
                id = 'm_theft',
                title = {
                    cs = 'Krádež cizí věci (Petty Theft)',
                    en = 'Theft / Petty Larceny',
                    de = 'Diebstahl fremden Eigentums'
                },
                fine = 2000,
                prison = 10
            },
            {
                id = 'm_gta',
                title = {
                    cs = 'Krádež motorového vozidla (GTA)',
                    en = 'Grand Theft Auto (Vehicle Theft)',
                    de = 'Schwerer Kraftfahrzeugdiebstahl (GTA)'
                },
                fine = 4500,
                prison = 15
            },
            {
                id = 'm_burglary',
                title = {
                    cs = 'Vloupání do objektu / obydlí',
                    en = 'Burglary / Breaking and Entering',
                    de = 'Einbruchdiebstahl in Gebäude/Wohnungen'
                },
                fine = 5000,
                prison = 20
            },
            {
                id = 'm_robbery_store',
                title = {
                    cs = 'Ozbrojené přepadení obchodu',
                    en = 'Armed Store Robbery',
                    de = 'Bewaffneter Überfall auf ein Geschäft'
                },
                fine = 7500,
                prison = 25
            },
            {
                id = 'm_robbery_bank',
                title = {
                    cs = 'Loupež finanční instituce / banky',
                    en = 'Bank Robbery / Heist',
                    de = 'Bankraub / Überfall auf ein Finanzinstitut'
                },
                fine = 15000,
                prison = 40
            }
        }
    },
    {
        category = {
            cs = 'Násilná trestná činnost',
            en = 'Violent Crimes',
            de = 'Gewaltdelikte'
        },
        items = {
            {
                id = 'v_assault_civ',
                title = {
                    cs = 'Fyzické napadení civilisty',
                    en = 'Assault and Battery on Civilian',
                    de = 'Körperverletzung an Zivilpersonen'
                },
                fine = 3000,
                prison = 10
            },
            {
                id = 'v_assault_cop',
                title = {
                    cs = 'Fyzické napadení policisty',
                    en = 'Assault on a Peace Officer',
                    de = 'Tätlicher Angriff auf Polizeibeamte'
                },
                fine = 6000,
                prison = 20
            },
            {
                id = 'v_deadly_weapon',
                title = {
                    cs = 'Napadení se smrtící zbraní',
                    en = 'Assault with a Deadly Weapon',
                    de = 'Gefährliche Körperverletzung mit tödlicher Waffe'
                },
                fine = 10000,
                prison = 30
            },
            {
                id = 'v_hostage',
                title = {
                    cs = 'Braní rukojmí / únos osoby',
                    en = 'Hostage Taking / Kidnapping',
                    de = 'Geiselnahme / Entführung einer Person'
                },
                fine = 15000,
                prison = 35
            },
            {
                id = 'v_attempted_murder',
                title = {
                    cs = 'Pokus o vraždu',
                    en = 'Attempted Murder',
                    de = 'Versuchter Mord / Totschlag'
                },
                fine = 20000,
                prison = 45
            },
            {
                id = 'v_murder',
                title = {
                    cs = 'Vražda prvního / druhého stupně',
                    en = 'First/Second Degree Murder',
                    de = 'Mord / Totschlag 1./2. Grades'
                },
                fine = 35000,
                prison = 60
            }
        }
    },
    {
        category = {
            cs = 'Zbraně a drogy',
            en = 'Weapons & Narcotics',
            de = 'Waffen und Betäubungsmittel'
        },
        items = {
            {
                id = 'w_illegal_carry',
                title = {
                    cs = 'Držení nelegální střelné zbraně (třída 1)',
                    en = 'Possession of Illegal Firearm (Class 1)',
                    de = 'Unerlaubter Besitz einer Schusswaffe (Klasse 1)'
                },
                fine = 4000,
                prison = 15
            },
            {
                id = 'w_illegal_heavy',
                title = {
                    cs = 'Držení vojenské / automatické zbraně (třída 2)',
                    en = 'Possession of Military/Automatic Weapon (Class 2)',
                    de = 'Besitz von Kriegswaffen / vollautomatischen Waffen (Klasse 2)'
                },
                fine = 10000,
                prison = 30
            },
            {
                id = 'w_discharge',
                title = {
                    cs = 'Neoprávněná střelba na veřejnosti',
                    en = 'Unlawful Discharge of Firearm in Public',
                    de = 'Unerlaubtes Abfeuern einer Waffe in der Öffentlichkeit'
                },
                fine = 5000,
                prison = 15
            },
            {
                id = 'd_possession_small',
                title = {
                    cs = 'Držení omamných látek pro vlastní potřebu',
                    en = 'Possession of Controlled Substances (Personal Use)',
                    de = 'Besitz von Betäubungsmitteln (Eigenbedarf)'
                },
                fine = 2000,
                prison = 5
            },
            {
                id = 'd_possession_intent',
                title = {
                    cs = 'Držení omamných látek za účelem distribuce',
                    en = 'Possession of Narcotics with Intent to Distribute',
                    de = 'Drogenbesitz mit der Absicht des Handeltreibens'
                },
                fine = 7000,
                prison = 25
            },
            {
                id = 'd_trafficking',
                title = {
                    cs = 'Výroba a distribuce drog ve velkém rozsahu',
                    en = 'Drug Manufacturing & Large-scale Trafficking',
                    de = 'Herstellung und Großhandel mit Betäubungsmitteln'
                },
                fine = 15000,
                prison = 40
            }
        }
    }
}
