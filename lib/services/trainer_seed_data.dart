import '../models/training_content.dart';

class TrainerSeedData {
  static List<TrainingText> getDiagnosticTexts() {
    return [
      // =======================================================================
      // ENGLISH TEXTS (Level 0 / Diagnostic)
      // =======================================================================
      TrainingText(
        id: 'diag-en-sleep',
        title: 'The Science of Sleep',
        level: 1, // diagnostic texts can be queried for level 1 or handled specially
        languageCode: 'en',
        wordCount: 304,
        topic: 'Health & Science',
        body: 'Sleep is a vital biological process that is essential for our survival and overall well-being. While we sleep, our bodies and minds undergo critical recovery processes. The sleep cycle is divided into two main types: Non-Rapid Eye Movement (NREM) sleep and Rapid Eye Movement (REM) sleep. NREM sleep consists of three stages, moving from light sleep to deep, restorative slow-wave sleep. During deep NREM sleep, the body repairs tissues, builds muscle, and boosts the immune system. REM sleep, on the other hand, is when most dreaming occurs. During REM sleep, brain activity increases to levels similar to when we are awake, and our eyes move rapidly. This stage is crucial for cognitive functions, particularly memory consolidation, learning, and emotional regulation. Our sleep is regulated by the circadian rhythm, an internal biological clock that responds to light and darkness in our environment. When light fades, the brain releases melatonin, a hormone that signals the body it is time to sleep. Modern lifestyle factors, such as blue light from electronic screens, caffeine, and irregular schedules, can easily disrupt this biological clock. Chronic sleep deprivation has been linked to numerous health issues, including weakened immunity, high blood pressure, memory lapses, and increased risk of cardiovascular disease. Adults generally require between seven and nine hours of quality sleep per night to function optimally. Prioritizing sleep is not a luxury, but a necessity for maintaining physical health, mental clarity, and emotional balance. Creating a consistent sleep routine, keeping the bedroom dark and cool, and avoiding screens before bed are simple yet effective strategies to improve sleep quality and enhance daily cognitive performance.',
        questions: [
          ComprehensionQuestion(
            id: 'q-diag-en-sleep-1',
            prompt: 'What are the two main types of sleep?',
            options: [
              'Light sleep and Deep sleep',
              'Circadian sleep and Melatonin sleep',
              'NREM sleep and REM sleep',
              'Active sleep and Passive sleep'
            ],
            correctOptionIndex: 2,
          ),
          ComprehensionQuestion(
            id: 'q-diag-en-sleep-2',
            prompt: 'During which stage of sleep does tissue repair primarily occur?',
            options: [
              'Deep NREM sleep',
              'Light NREM sleep',
              'REM sleep',
              'Melatonin phase'
            ],
            correctOptionIndex: 0,
          ),
          ComprehensionQuestion(
            id: 'q-diag-en-sleep-3',
            prompt: 'What role does REM sleep play in cognitive function?',
            options: [
              'It lowers brain activity to zero',
              'It consolidates memory, learning, and emotional regulation',
              'It is responsible for tissue and muscle building',
              'It has no impact on mental performance'
            ],
            correctOptionIndex: 1,
          ),
          ComprehensionQuestion(
            id: 'q-diag-en-sleep-4',
            prompt: 'Which hormone signals the body that it is time to sleep?',
            options: [
              'Caffeine',
              'Adrenaline',
              'Cortisol',
              'Melatonin'
            ],
            correctOptionIndex: 3,
          ),
          ComprehensionQuestion(
            id: 'q-diag-en-sleep-5',
            prompt: 'How many hours of sleep do adults generally need per night?',
            options: [
              '5 to 6 hours',
              '7 to 9 hours',
              '10 to 12 hours',
              'Exactly 8 hours'
            ],
            correctOptionIndex: 1,
          ),
        ],
      ),
      TrainingText(
        id: 'diag-en-tea',
        title: 'The History of Tea',
        level: 1,
        languageCode: 'en',
        wordCount: 308,
        topic: 'History & Culture',
        body: 'Tea is one of the most popular beverages in the world, enjoyed by millions of people across diverse cultures. According to Chinese legend, tea was discovered in 2737 BCE by Emperor Shennong when wild tea leaves accidentally drifted into his pot of boiling water. Intrigued by the pleasant aroma and refreshing taste, the emperor began researching the plant’s properties, leading to the birth of tea drinking. Initially, tea was consumed primarily for its medicinal benefits, acting as a digestive aid and stimulant. It wasn’t until the Tang Dynasty in China that tea drinking evolved into a sophisticated art and social ritual. Buddhist monks played a significant role in spreading tea culture, using the beverage to stay awake during long hours of meditation. Tea was introduced to Japan in the 9th century, where it eventually led to the development of the famous Japanese tea ceremony. European traders first encountered tea in East Asia during the early 16th century. Portuguese and Dutch merchants began importing it, and it quickly became a luxury item among European elites. By the 17th century, tea reached England, where it grew into a national obsession. The British East India Company established massive tea plantations in India to break the Chinese monopoly on tea trade, introducing black tea to the Western world. Today, tea is classified into several main types—green, black, oolong, white, and herbal—all originating from the leaves of the Camellia sinensis plant, except for herbal teas. The differences in flavor and color result from the level of oxidation the leaves undergo during processing. From ancient medicinal brew to global social staple, tea remains a symbol of hospitality, mindfulness, and cultural heritage.',
        questions: [
          ComprehensionQuestion(
            id: 'q-diag-en-tea-1',
            prompt: 'According to legend, who discovered tea?',
            options: [
              'A Japanese monk',
              'Emperor Shennong',
              'A Portuguese merchant',
              'A British colonial trader'
            ],
            correctOptionIndex: 1,
          ),
          ComprehensionQuestion(
            id: 'q-diag-en-tea-2',
            prompt: 'How was tea initially consumed in ancient times?',
            options: [
              'Mainly for its medicinal benefits',
              'As a ceremonial offering only',
              'As a sweet dessert beverage',
              'It was used to dye fabrics'
            ],
            correctOptionIndex: 0,
          ),
          ComprehensionQuestion(
            id: 'q-diag-en-tea-3',
            prompt: 'Who helped spread tea culture to help stay awake during meditation?',
            options: [
              'European traders',
              'British soldiers',
              'Buddhist monks',
              'Chinese emperors'
            ],
            correctOptionIndex: 2,
          ),
          ComprehensionQuestion(
            id: 'q-diag-en-tea-4',
            prompt: 'Which plant do green, black, white, and oolong teas originate from?',
            options: [
              'Camellia sinensis',
              'Herbal tea flower',
              'Indian black bush',
              'Shennong herb'
            ],
            correctOptionIndex: 0,
          ),
          ComprehensionQuestion(
            id: 'q-diag-en-tea-5',
            prompt: 'What process determines the final flavor and color differences of teas?',
            options: [
              'The temperature of the boiling water',
              'The level of oxidation during processing',
              'The altitude where the plant grows',
              'The shape of the tea pot'
            ],
            correctOptionIndex: 1,
          ),
        ],
      ),
      TrainingText(
        id: 'diag-en-printing',
        title: 'The Gutenberg Press',
        level: 1,
        languageCode: 'en',
        wordCount: 312,
        topic: 'Technology & History',
        body: 'In the mid-15th century, a German goldsmith named Johannes Gutenberg invented the movable-type printing press, an innovation that would forever change human history. Before Gutenberg’s invention, books were copied by hand, a slow and labor-intensive process performed mostly by scribes in monasteries. Because of this, books were extremely rare, expensive, and accessible only to the wealthy elite and the clergy. Gutenberg’s key breakthrough was combining metal movable type, oil-based ink, and a wooden screw press. This allowed for the rapid, uniform, and mass production of text. The first major book printed using this technology was the Gutenberg Bible in 1455, which demonstrated the beauty and feasibility of the process. The impact of the printing press was immediate and revolutionary. Within a few decades, printing shops spread across Europe, producing millions of books. This sudden abundance of books caused the cost of literature to plummet, making reading materials accessible to the general public for the first time. The press played a critical role in the spread of ideas. It facilitated the Renaissance, fueled the Protestant Reformation, and laid the groundwork for the Scientific Revolution by allowing researchers to share and build upon each other’s discoveries. Literacy rates soared as people had a practical reason and opportunity to learn to read. News, pamphlets, and political tracts could be printed and distributed rapidly, creating an informed public and challenging traditional authorities. Gutenberg’s press is widely regarded as one of the most important inventions of the second millennium, bridging the Middle Ages and the modern era by democratizing knowledge and information flow.',
        questions: [
          ComprehensionQuestion(
            id: 'q-diag-en-print-1',
            prompt: 'Who invented the movable-type printing press?',
            options: [
              'Johannes Gutenberg',
              'A French scribe',
              'Shennong the Goldsmith',
              'Emperor Tang'
            ],
            correctOptionIndex: 0,
          ),
          ComprehensionQuestion(
            id: 'q-diag-en-print-2',
            prompt: 'How were books produced before the printing press?',
            options: [
              'Using wooden stamps',
              'Copied by hand by scribes',
              'Imported from East Asia',
              'They did not exist'
            ],
            correctOptionIndex: 1,
          ),
          ComprehensionQuestion(
            id: 'q-diag-en-print-3',
            prompt: 'What was the first major book printed by Gutenberg in 1455?',
            options: [
              'The Gutenberg Bible',
              'The History of Tea',
              'The Science of Sleep',
              'A dictionary of terms'
            ],
            correctOptionIndex: 0,
          ),
          ComprehensionQuestion(
            id: 'q-diag-en-print-4',
            prompt: 'Which of the following historical movements was NOT directly fueled by the printing press?',
            options: [
              'The Protestant Reformation',
              'The Scientific Revolution',
              'The Industrial Revolution',
              'The Renaissance'
            ],
            correctOptionIndex: 2,
          ),
          ComprehensionQuestion(
            id: 'q-diag-en-print-5',
            prompt: 'Why did the invention of the printing press increase literacy rates?',
            options: [
              'Governments made reading mandatory',
              'Books became cheap and widely accessible',
              'Scribes taught everyone for free',
              'It was the only source of entertainment'
            ],
            correctOptionIndex: 1,
          ),
        ],
      ),

      // =======================================================================
      // RUSSIAN TEXTS (Level 0 / Diagnostic)
      // =======================================================================
      TrainingText(
        id: 'diag-ru-sleep',
        title: 'Наука о сне',
        level: 1,
        languageCode: 'ru',
        wordCount: 301,
        topic: 'Здоровье и наука',
        body: 'Сон — это жизненно важный биологический процесс, необходимый для нашего выживания и общего благополучия. Пока мы спим, в организме происходят критические восстановительные процессы. Цикл сна делится на два основных типа: сон без быстрого движения глаз (NREM) и сон с быстрым движением глаз (REM). NREM-сон состоит из трех стадий, переходящих от легкого сна к глубокому, восстанавливающему медленноволновому сну. Во время глубокого NREM-сна организм восстанавливает ткани, строит мышечную массу и укрепляет иммунную систему. С другой стороны, REM-сон — это фаза, когда происходит большинство сновидений. Во время REM-сна активность мозга возрастает до уровней, близких к состоянию бодрствования, а наши глаза быстро двигаются. Эта стадия имеет решающее значение для когнитивных функций, особенно для консолидации памяти, обучения и эмоциональной регуляции. Наш сон регулируется циркадным ритмом — внутренними биологическими часами, реагирующими на свет и темноту в окружающей среде. Когда свет гаснет, мозг выделяет мелатонин — гормон, сигнализирующий организму о том, что пора спать. Современные факторы образа жизни, такие как синий свет от электронных экранов, кофеин и нерегулярный график, могут легко нарушить эти биологические часы. Хроническое недосыпание связано со многими проблемами со здоровьем, включая ослабление иммунитета, высокое кровяное давление, провалы в памяти и повышенный риск сердечно-сосудистых заболеваний. Взрослым людям обычно требуется от семи до девяти часов качественного сна в сутки для оптимального функционирования. Приоритет сна — это не роскошь, а необходимость для поддержания физического здоровья и умственной ясности. Создание постоянного режима сна, поддержание прохлады в спальне и отказ от гаджетов перед сном — простые, но эффективные стратегии улучшения качества сна.',
        questions: [
          ComprehensionQuestion(
            id: 'q-diag-ru-sleep-1',
            prompt: 'На какие два основных типа делится сон?',
            options: [
              'Легкий и глубокий сон',
              'Циркадный и мелатониновый сон',
              'NREM-сон и REM-сон',
              'Активный и пассивный сон'
            ],
            correctOptionIndex: 2,
          ),
          ComprehensionQuestion(
            id: 'q-diag-ru-sleep-2',
            prompt: 'В какую фазу сна в основном происходит восстановление тканей?',
            options: [
              'Глубокий NREM-сон',
              'Легкий NREM-сон',
              'REM-сон',
              'Фаза выделения мелатонина'
            ],
            correctOptionIndex: 0,
          ),
          ComprehensionQuestion(
            id: 'q-diag-ru-sleep-3',
            prompt: 'Какую роль играет REM-сон в когнитивных функциях?',
            options: [
              'Снижает активность мозга до нуля',
              'Способствует консолидации памяти, обучению и эмоциональной регуляции',
              'Отвечает за рост мышечной ткани',
              'Не влияет на умственные способности'
            ],
            correctOptionIndex: 1,
          ),
          ComprehensionQuestion(
            id: 'q-diag-ru-sleep-4',
            prompt: 'Какой гормон сигнализирует организму о необходимости сна?',
            options: [
              'Кофеин',
              'Адреналин',
              'Кортизол',
              'Мелатонин'
            ],
            correctOptionIndex: 3,
          ),
          ComprehensionQuestion(
            id: 'q-diag-ru-sleep-5',
            prompt: 'Сколько часов сна обычно требуется взрослому человеку в сутки?',
            options: [
              'От 5 до 6 часов',
              'От 7 до 9 часов',
              'От 10 до 12 часов',
              'Ровно 8 часов'
            ],
            correctOptionIndex: 1,
          ),
        ],
      ),
      TrainingText(
        id: 'diag-ru-tea',
        title: 'История чая',
        level: 1,
        languageCode: 'ru',
        wordCount: 303,
        topic: 'История и культура',
        body: 'Чай — один из самых популярных напитков в мире, который любят миллионы людей в самых разных культурах. Согласно китайской легенде, чай был открыт в 2737 году до нашей эры императором Шэнь-нуном, когда дикие листья чая случайно упали в его котел с кипящей водой. Заинтригованный приятным ароматом и освежающим вкусом, император начал исследовать свойства этого растения, что положило начало культуре чаепития. Первоначально чай употреблялся в основном в медицинских целях, как средство для улучшения пищеварения и стимулятор. Только во времена династии Тан в Китае чаепитие превратилось в утонченное искусство и социальный ритуал. Буддийские монахи сыграли важную роль в распространении чайной культуры, используя напиток для поддержания бодрствования во время долгих часов медитации. Чай был завезен в Японию в IX веке, где со временем сформировалась знаменитая японская чайная церемония. Европейские торговцы впервые столкнулись с чаем в Восточной Азии в начале XVI века. Португальские и голландские купцы начали импортировать его, и он быстро стал предметом роскоши среди европейской элиты. К XVII веку чай достиг Англии, где превратился в национальную страсть. Британская Ост-Индская компания основала огромные чайные плантации в Индии, чтобы разрушить китайскую монополию на торговлю чаем, открыв черный чай западному миру. Сегодня чай классифицируется на несколько основных видов: зеленый, черный, улун, белый и травяной. Все они, за исключением травяных чаев, производятся из листьев растения Camellia sinensis. Разница во вкусе и цвете является результатом степени окисления, которой подвергаются листья во время обработки.',
        questions: [
          ComprehensionQuestion(
            id: 'q-diag-ru-tea-1',
            prompt: 'Кто, согласно легенде, открыл чай?',
            options: [
              'Японский монах',
              'Император Шэнь-нун',
              'Португальский купец',
              'Британский колонизатор'
            ],
            correctOptionIndex: 1,
          ),
          ComprehensionQuestion(
            id: 'q-diag-ru-tea-2',
            prompt: 'Как изначально употреблялся чай в древности?',
            options: [
              'В основном в медицинских целях',
              'Исключительно как церемониальное подношение',
              'Как сладкий десертный напиток',
              'Для окрашивания тканей'
            ],
            correctOptionIndex: 0,
          ),
          ComprehensionQuestion(
            id: 'q-diag-ru-tea-3',
            prompt: 'Кто способствовал распространению чая для бодрствования во время медитации?',
            options: [
              'Европейские купцы',
              'Британские солдаты',
              'Буддийские монахи',
              'Китайские императоры'
            ],
            correctOptionIndex: 2,
          ),
          ComprehensionQuestion(
            id: 'q-diag-ru-tea-4',
            prompt: 'Из какого растения производят зеленый, черный, белый чай и улун?',
            options: [
              'Camellia sinensis',
              'Цветок травяного чая',
              'Индийский черный куст',
              'Трава Шэнь-нуна'
            ],
            correctOptionIndex: 0,
          ),
          ComprehensionQuestion(
            id: 'q-diag-ru-tea-5',
            prompt: 'Какой процесс определяет различия во вкусе и цвете чая?',
            options: [
              'Температура кипения воды',
              'Степень окисления листьев при обработке',
              'Высота произрастания чайного куста',
              'Форма заварочного чайника'
            ],
            correctOptionIndex: 1,
          ),
        ],
      ),
      TrainingText(
        id: 'diag-ru-printing',
        title: 'Печатный станок Гутенберга',
        level: 1,
        languageCode: 'ru',
        wordCount: 304,
        topic: 'Технологии и история',
        body: 'В середине XV века немецкий золотых дел мастер Иоганн Гутенберг изобрел печатный станок с подвижными литерами — инновацию, которая навсегда изменила человеческую историю. До этого книги переписывались вручную. Это был медленный и трудоемкий процесс, выполнявшийся в основном монахами в монастырях. Из-за этого книги были крайне редкими, дорогими и доступными только богатой элите и духовенству. Прорыв Гутенберга заключался в объединении металлических подвижных литер, чернил на масляной основе и деревянного винтового пресса. Это позволило осуществлять быстрое, единообразное и массовое производство текстов. Первой крупной книгой, напечатанной по этой технологии, стала Библия Гутенберга в 1455 году. Влияние печатного станка было мгновенным. За несколько десятилетий типографии распространились по всей Европе, выпустив миллионы книг. Внезапное обилие литературы привело к резкому падению ее стоимости, сделав книги впервые доступными для широкой публики. Печатный станок сыграл важнейшую роль в распространении идей. Он способствовал развитию Возрождения, подпитал Реформацию и заложил основу для Научной революции, позволив ученым делиться открытиями и опираться на работы друг друга. Уровень грамотности резко вырос, так как у людей появилась практическая причина учиться читать. Новости и политические трактаты могли печататься и распространяться мгновенно, формируя информированное общественное мнение. Станок Гутенберга считается одним из важнейших изобретений второго тысячелетия, объединившим Средневековье и современную эпоху путем демократизации знаний.',
        questions: [
          ComprehensionQuestion(
            id: 'q-diag-ru-print-1',
            prompt: 'Кто изобрел печатный станок с подвижными литерами?',
            options: [
              'Иоганн Гутенберг',
              'Французский писец',
              'Шэнь-нун',
              'Император Тан'
            ],
            correctOptionIndex: 0,
          ),
          ComprehensionQuestion(
            id: 'q-diag-ru-print-2',
            prompt: 'Как создавались книги до изобретения печатного станка?',
            options: [
              'С помощью деревянных штампов',
              'Переписывались вручную писцами',
              'Импортировались из Восточной Азии',
              'Книг не существовало'
            ],
            correctOptionIndex: 1,
          ),
          ComprehensionQuestion(
            id: 'q-diag-ru-print-3',
            prompt: 'Какая книга была впервые напечатана Гутенбергом в 1455 году?',
            options: [
              'Библия Гутенберга',
              'История чая',
              'Наука о сна',
              'Словарь терминов'
            ],
            correctOptionIndex: 0,
          ),
          ComprehensionQuestion(
            id: 'q-diag-ru-print-4',
            prompt: 'Какое из исторических движений НЕ было напрямую подпитано печатным станком?',
            options: [
              'Протестантская Реформация',
              'Научная революция',
              'Промышленная революция',
              'Эпоха Возрождения'
            ],
            correctOptionIndex: 2,
          ),
          ComprehensionQuestion(
            id: 'q-diag-ru-print-5',
            prompt: 'Почему изобретение печатного станка повысило уровень грамотности?',
            options: [
              'Правительства сделали чтение обязательным',
              'Книги стали дешевыми и общедоступными',
              'Переписчики бесплатно учили всех желающих',
              'Чтение стало единственным развлечением'
            ],
            correctOptionIndex: 1,
          ),
        ],
      ),
    ];
  }
}
