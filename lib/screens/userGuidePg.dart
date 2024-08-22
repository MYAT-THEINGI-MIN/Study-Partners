import 'package:flutter/material.dart';

class UserGuidePg extends StatelessWidget {
  const UserGuidePg({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Guide'),
        backgroundColor: Colors.deepPurple,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Introduction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '- Study Partner app သည် ကျောင်းသူ/သားများကို Plan ရေးဆွဲခြင်း၊ စာလေ့လာခြင်းနှင့် အတူတကွ ပူးပေါင်းဆောင်ရွက်ခြင်းများအား ထိရောက်စွာ လုပ်ဆောင်နိုင်ရန် ဖန်းတီးထားသည့် Appဖြစ်သည်။\n'
              '- အသုံးပြုသူ၏ ကိုယ်ပိုင် အချိန်ဇယားများကို စီမံခန့်ခွဲရန်၊ အုပ်စုဖွဲ့ စာလေ့လာခြင်းနှင့် လေ့လာရန် လိုအပ်သော အရင်းအမြစ်များကို Study Partner App မှ အသုံးပြုသူများအချင်းချင်းကူညီပံ့ပိုးပေးနိုင်မည့်နေရာဖြစ်သည်။',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '2. Getting Started: Sign Up / Log In',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '- သင့်အီးမေးလ်နဲ့ စကားဝှက်ကို အသုံးပြု၍ အကောင့် ဖွင့်ရမည် (သို့မဟုတ်) အ‌ကောင့် ဖွင့်ပြီးသား ဖြစ်ပါက Log in ဝင်ရောက်ရပါမည်။\n'
              '- Profile Setup: သင့်၏ ပရိုဖိုင်ဓာတ်ပုံ၊ အမည်၊ ယခုလက်ရှိတွင်သင် စိတ်ဝင်စားသော သို့မဟုတ်လေ့လာနေဆဲဖြစ်သော ဘာသာရပ်များကို ထည့်သွင်းပြီး သင့်ပရိုဖိုင်ကို စိတ်ကြိုက်ပြင်ဆင်ပါ။',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '3. Main Features Overview: Planner Page',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '- သင်၏ အလုပ်များကို စီစဉ်ခြင်း၊ အချိန်စာရင်းများ သတ်မှတ်ခြင်းနှင့် သတ်မှတ်ထားသောအချိန်တွင် အစီအမံများအား planner page တွင်စီမံနိုင်ပါသည်။\n'
              '- Group Study and Planner: အသုံးပြုသူ၏ partnerများနှင့် group ဖွဲ့ခြင်း၊ schedule plan များအား မျှ‌‌‌ဝေနိုင်ခြင်း၊ group ၏ လုပ်ဆောင်ချက်များအား အသုံးပြုနိုင်သည်။\n'
              '- Chat and Collaboration: Study Partner App ၏ chat feature များကို အသုံးပြု၍ အခြားသော အသုံးပြုသူများနှင့် ဆက်သွယ်ဆောင်ရွက်နိုင်သည်။',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '4. Using the Planner: Adding Tasks and Remainders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Add New Task တွင် အသုံးပြုသူ လုပ်ဆောင်လိုသော Plan ၏ ခေါင်းစဉ်၊ လုပ်ဆောင်ရမည့်ရက်စွဲ၊ အချိန်နှင့် သတိပေးချက်များကို သတ်မှတ်နိုင်သည်။ သတိပေးချက်များကို သတ်မှတ်ထားလျှင် မိမိသတ်မှတ်ထားသည့် အချိန်ကို သတိပေးမည်ဖြစ်ပါသည်။',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '5. Group Study Management: Creating or Joining Groups',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '- အသုံးပြုသူသည် မိမိစိတ်ဝင်စားသော group များကို ရှာဖွေ၍ ဝင်ရောက်နိုင်သည် (သို့မဟုတ်) group အတွင်း၌ ရှိနှင့်ပြီးသော အသုံးပြုသူ၏ ဖိတ်ကြားချက်ဖြင့် ဝင်ရောက်နိုင်သည်။\n'
              '- Group chat: Chat feature ကို အသုံးပြု၍ မိမိတို့နှစ်သက်သော အကြောင်းအရာများအား ဆွေနွေးခြင်း၊ schedule plan များအား မျှ‌‌‌ဝေနိုင်ခြင်း၊ အသုံးပြုသူများ အကြား ပြုလုပ်လိုသည်များကို ဆောင်ရွက်နိုင်သည်။',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '6. Task Sharing and Collaboration: Sharing Tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '- အသုံးပြုသူများသည် group အတွင်း မိမိ မျှဝေလိုသော အကြောင်းအရာများကို မျှဝေနိုင်သည်။\n'
              '- Collaboration Study Plans: အသုံးပြုသူများသည် group အတွင်းရှိ အခြားသော အသုံးပြုသူများ မျှဝေထားသော အချက်လက်များနှင့် schedule plan များအား အတူတကွ ပူးပေါင်းဆောင်ရွက်လေ့လာနိုင်သည်။\n'
              '- Leaderboard and Points: Group အတွင်း tasks များကို ပြီးမြောက်စွာ ဆောင်ရွက်ပြီးနောက် မိမိ၏ Points ရရှိမှုပေါ် မူတည်၍ Group Leaderboard တွင် ဖော်ပြထားမည်ဖြစ်သည်။',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '7. Flashcards and Quiz Features: Creating Flashcards',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '- အသုံးပြုသူများသည် မိမိထည့်သွင်းလိုသော အကြောင်းအရာများကို Flashcards တွင် ထည့်သွင်း၍ group အတွင်းရှိ အခြားသော အသုံးပြုသူများကို မျှဝေနိုင်သည်။\n'
              '- အသုံးပြုသူများသည် မိမိ ဖန်တီးထားသော Quiz များကို group အတွင်းရှိ အခြားသော အသုံးပြုသူများကို မျှဝေနိုင်သည်။',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '8. Contacting Support',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'အဆင်မပြေမှုများအတွက် App မှတဆင့် ကျွန်ုပ်တို့၏ Developer Teamကို ဆက်သွယ်နိုင်ပါသည်။\n'
              'Email: myattheingimin3532@gmail.com \n yairzawhtun007@gmail.com \n pyaitsonephyoe2785@gmail.com',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
