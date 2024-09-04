import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy and Policy'),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Study Partner App Rules',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                '၁။ မိတ်ဆက်\n'
                'Study Partner ကိုသုံးစွဲခြင်းဖြင့် အောက်ပါစည်းမျဉ်းများကို လိုက်နာရန် သဘောတူရပါမည်။ ဤစည်းမျဉ်းများသည် အသုံးပြုသူများအတွက် ထိရောက်မှု နှင့် တိုးတက်မှုရှိသော ပတ်ဝန်းကျင်ကို ဖန်တီးရန် ရည်ရွယ်ပါသည်။',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '၂။ အကောင့်စီမံခန့်ခွဲမှု\n'
                '- Sign Up / Log In: အကောင့်တစ်ခုကို ဖန်တီးစဉ် (သို့မဟုတ်) log in လုပ်စဉ်တွင် မှန်ကန်သော အချက်အလက်များကို အသုံးပြုရမည်။ သင့် log in အချက်အလက်များကို လုံခြုံစွာ သိမ်းဆည်းထားရမည်။ (သို့မဟုတ်) အခြားသူများနှင့် မမျှဝေရပါ။\n'
                '- Profile Setup: သင့်ပရိုဖိုင်အချက်အလက်များ၊ ပရိုဖိုင်ပုံနှင့် သင်လေ့လာလိုသော ဘာသာရပ်များအား အမှန်တကယ်ဖြစ်ရန်နှင့် သင့်တော်မှုရှိရန် သေချာရန် လိုအပ်ပါသည်။',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '၃။ လုပ်ဆောင်ချက်များအသုံးပြုခြင်း\n'
                '- Planner Page: သင်လုပ်ဆောင်လိုသော အကြောင်းအရာများနှင့် အချိန်ကို Planner page တွင် သတ်မှတ်နိုင်သည်။\n'
                '- Group Study and Planner: သင်၏ အဖွဲ့ဝင်များနှင့် ပူးပေါင်းဆောင်ရွက်ရပါမည်။ မိမိ၏ အဖွဲ့ဝင်များ အကျိုးရှိစေသော planများကိုသာ မျှဝေပါ။\n'
                '- Chat and Collaboration: Chat တွင် အခြားသော အသုံးပြုသူများနှင့် အပြန်အလှန် ဆက်သွယ်ရာ၌ ယဥ်ကျေးစွာ ပြုမှုပြောဆိုရမည်။ Group အတွင်း ပြောဆိုရန်မသင့်တော်သော (သို့မဟုတ်) နောက်ပြောင်သော အပြုအမူများကို ခွင့်မပြုပါ။',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '၄။ တာဝန်စီမံခန့်ခွဲမှု\n'
                '- Adding Tasks: Task များကို ထည့်သွင်းစဥ် မှန်ကန်သော အသေးစိတ်အချက်အလက်များကို ထည့်သွင်းရမည်။ Group အတွင်း မှားယွင်းသော (သို့မဟုတ်) ထင်ယောင်ထင်မှား ဖြစ်စေသော အချက်အလက်များကို ဖော်ပြရန် ခွင့်မပြုပါ။\n'
                '- Setting Reminders: သင်၏ task များကို သတ်မှတ်ချိန်အတွင်း ပြီးစီးရန် သင်ကိုယ်တိုင် စီမံ ခန့်ခွဲရမည်။ ကျွန်ုပ်တို့ app မှ သင်၏ အစီအစဥ်များကို သိမ်းဆည်းရန် ကူညီပေးနိုင်သော်လည်း သင်၏တာဝန်များကို ပြီးစီးရန်မှာ သင်ကိုယ်တိုင် တာဝန်ယူရမည် ဖြစ်သည်။',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '၅။ အဖွဲ့လိုက်စာလေ့ကျင့်မှု စည်းမျဉ်းများ\n'
                '- Creating or Joining Groups: ‌ဘာသာရပ်အလိုက် group များတွင် တက်ကြွစွာနှင့် လေးစားစွာ ပါဝင်ပူးပေါင်းဆောင်ရွက်ရမည်။ Group အတွင်း ဘာသာရပ်နှင့် မသက်ဆိုင်သော အကြောင်းအရာများကို ဝေမျှခြင်း ပြုလျှင် group adminမှသင့်အား groupမှ ဖယ်ရှားခြင်းမည် ဖြစ်သည်။\n'
                '- Group Chat: Group Chat အတွင်း ဘာသာရပ်နှင့် သက်ဆိုင်သော အချက်အလက်များကိုသာ ဆွေးနွေးတိုင်ပင်နိုင်သည်။',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '၆။ တာဝန်မျှဝေခြင်းနှင့်ပူးပေါင်းမှု\n'
                '- Sharing Tasks: Group အတွင်း အဖွဲ့နှင့်သက်ဆိုင်သော task များကိုသာ မျှဝေနိုင်သည်။ သင်မျှဝေလိုသည့် အချက်အလက်များသည် မှန်ကန်၍ အဖွဲ့အတွက် အကျိုးရှိစေရမည်။\n'
                '- Leaderboards and Points:အဖွဲ့အတွင်း မလိုအပ်သော ယှဉ်ပြိုင်မှု (သို့မဟုတ်) ဖိအားများ ဖန်တီးခြင်းကို ရှောင်ကြဉ်ပါ။',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '၇။ Flashcards နှင့် Quizzes\n'
                '- Creating Flashcards: Flashcards များကို မှန်ကန်စွာ ဖန်တီးပါ။ မျှဝေလိုပါက အဖွဲ့အတွက် အကျိုးရှိမည်ဟု သေချာရမည်။\n'
                '- Taking Quizzes: Quizzes များသည် သင်ယူခြင်းနှင့် လေ့လာခြင်းအတွက်ဖြစ်သည်။ အပြိုင်အဆိုင်အဖြစ် ဖန်တီးခြင်း မဖြစ်စေဘဲ သင်၏ အသိပညာ တိုးတက်စေရန် အတွက်သာ အသုံးပြုပါ။',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '၈။ Contacting Support\n'
                'ပြဿနာများ ကြုံတွေ့ရပါက (သို့မဟုတ်) အကူအညီလိုအပ်ပါက ကျွန်ုပ်တို့၏ အဖွဲ့နှင့် ဆက်သွယ်နိုင်သည်။\n'
                'Email: myattheingimin3532@gmail.com\n yairzawhtun007@gmail.com \n pyaitsonephyoe2785@gmail.com',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '၉။ Respectful Behavior\n'
                '- Respectful Behavior: အသုံးပြုသူများအားလုံးကို လေးစားစွာ ဆက်ဆံပါ။ ရိုင်းပြခြင်း၊ အနိုင်ကျင့်ခြင်း (သို့မဟုတ်) မသင့်တော်သော အပြုအမူများကို ခွင့်မပြုပါ။\n'
                '- Content Accuracy: သင်ဖန်တီးသည့် (သို့မဟုတ်) မျှဝေသည့် အကြောင်းအရာများသည် မှန်ကန်ပြီး အကျိုးရှိရန် သေချာပါစေ။ မှားယွင်းသော (သို့မဟုတ်) မှားယွင်းသိမြင်နိုင်သော အကြောင်းအရာများသည် အဖွဲ့၏ စာလေ့လာမှုများကို ထိခိုက်စေနိုင်ပါသည်။\n'
                '- Privacy: အခြားသူများ၏ ကိုယ်ရေးအချက်အလက်များကို လေးစားပါ။ ခွင့်ပြုချက်မရှိဘဲ ကိုယ်ရေးအချက်အလက်များ (သို့မဟုတ်) မျှဝေခြင်း မလုပ်ပါနှင့်။',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
