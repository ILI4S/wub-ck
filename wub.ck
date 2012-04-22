//
// wub.ck
// by Ilias Karim
// dx.xb
//

MAUI_View view;
view.name("dx.xb");
view.size(240, 610);
view.display();

MAUI_LED led;
led.color(led.red);
view.addElement(led);
led.position(85, 0);

MAUI_Slider freqSlider;
"freq" => freqSlider.name;
//gainSlider.size(200, 200);
freqSlider.range(0, 50);
freqSlider.value(25);
view.addElement(freqSlider);
freqSlider.position(0, 40);

MAUI_Slider gainSlider;
"gain" => gainSlider.name;
//gainSlider.size(200, 200);
gainSlider.range(0, .05 );
gainSlider.value(.001);
view.addElement(gainSlider);
gainSlider.position(0, 90);

MAUI_Slider feedbackGainSlider;
"feedback gain" => feedbackGainSlider.name;
feedbackGainSlider.display();
feedbackGainSlider.range(0, .8);
feedbackGainSlider.value(0);
view.addElement(feedbackGainSlider);
feedbackGainSlider.position(0, 140);

MAUI_Slider reverbMixSlider;
"reverb mix" => reverbMixSlider.name;
reverbMixSlider.display();
reverbMixSlider.range(0, .1);
reverbMixSlider.value(.01);
view.addElement(reverbMixSlider);
reverbMixSlider.position(0, 190);

MAUI_Slider delayDurationSlider;
"delay duration (ms)" => delayDurationSlider.name;
delayDurationSlider.display();
delayDurationSlider.range(500, 750);
delayDurationSlider.value(750);
view.addElement(delayDurationSlider);
delayDurationSlider.position(0, 240);

MAUI_Slider envelopeDurationSlider;
"envelope duration (ms)" => envelopeDurationSlider.name;
envelopeDurationSlider.display();
envelopeDurationSlider.range(0, 200);
envelopeDurationSlider.value(50);
view.addElement(envelopeDurationSlider);
envelopeDurationSlider.position(0, 290);

MAUI_Slider keyOnDurationSlider;
"key on duration (ms)" => keyOnDurationSlider.name;
keyOnDurationSlider.display();
keyOnDurationSlider.range(0, 200);
keyOnDurationSlider.value(50);
view.addElement(keyOnDurationSlider);
keyOnDurationSlider.position(0, 340);

MAUI_Slider keyOffDurationSlider;
"key off duration (ms)" => keyOffDurationSlider.name;
keyOffDurationSlider.display();
keyOffDurationSlider.range(0, 1000);
keyOffDurationSlider.value(400);
view.addElement(keyOffDurationSlider);
keyOffDurationSlider.position(0, 390);

MAUI_Slider resQSlider;
"res.Q" => resQSlider.name;
resQSlider.display();
resQSlider.range(.1, 1);
resQSlider.value(.1);
view.addElement(resQSlider);
resQSlider.position(0, 440);

MAUI_Slider resFreqScaleSlider;
"res freq scale" => resFreqScaleSlider.name;
resFreqScaleSlider.display();
resFreqScaleSlider.range(.1, 15);
resFreqScaleSlider.value(.1);
view.addElement(resFreqScaleSlider);
resFreqScaleSlider.position(0, 490);

//MAUI_Button on_button;
//on_button.size(64, 64);
//view.addElement(on_button);
//on_button.position(50, 519);

MAUI_Button buttons[3];

for (0 => int i; i < buttons.size(); i++)
{
    MAUI_Button toggle_button;
    toggle_button.toggleType();
    toggle_button.size(64, 64);
    view.addElement(toggle_button);
    toggle_button.position(i * 43, 550);
    toggle_button @=> buttons[i];
}

buttons[0].state(1);

Math.min(6, dac.channels()) $ int => int NUM_CHANNELS;

// patch
SawOsc s => ResonZ res => Envelope e => NRev r => dac.chan(0);
e => Delay d => r;
d => Gain feedback => d;

for (0 => int i; i < NUM_CHANNELS; i++)
    s => res => e => r => dac.chan(i);

// max params
1::second => d.max;

0 => float isPlaying;

0 => int offset;

0 => int counter;


spork ~ handleKB();                                                                                   
fun void handleKB()
{
    Hid hi;
    HidMsg msg;
    
    0 => int device;
    hi.openKeyboard(device);
    
    while (true)
    {
        hi => now;
        
        while (hi.recv(msg))
        {
            envelopeDurationSlider.value()::ms => e.duration;
            delayDurationSlider.value()::ms => d.delay;
            reverbMixSlider.value() => r.mix;
            feedbackGainSlider.value() => feedback.gain;
            gainSlider.value() => s.gain;
            
            Std.mtof(freqSlider.value() $ int + offset) => float freq;
            freq => s.freq;
            freq * resFreqScaleSlider.value() => res.freq;
            resQSlider.value() => res.Q;
            
            <<< msg.ascii >>>;
            
            if (msg.isButtonDown() && msg.ascii >= 48 && msg.ascii <= 57)
            {
                msg.ascii - 48 => offset;
            }
            
            
            if (msg.ascii == 32)
            {
                if (msg.isButtonDown())      
                {                                                        
                    e.keyOn();
                    led.light();
                    counter++;
                    counter % 8 => counter;
                    
                    <<< counter >>>;
                     
                    if (counter == 0)
                        0 => offset;
                    else if (counter == 4)
                        3 => offset;
                }
                
                else if (msg.isButtonUp()) 
                {
                    e.keyOff();
                    led.unlight();
                }
            }
            
            if (msg.isButtonDown() && msg.ascii == 9)
            {
                for (0 => int i; i < buttons.size(); i++)
                {

                    if (buttons[i].state())
                    {
                        buttons[i].state(0);
                        buttons[(i + 1) % buttons.size()].state(10);
                        break;
                   }
                }
            }   
        }
    }
}


spork ~ handleMultitouch();

fun void handleMultitouch()
{
    Hid hi;
    hi.open(7, 1);
    
    HidMsg msg;
    
    while(true)
    {
        hi => now;
        while(hi.recv(msg))
        {
            //<<<  >>>;
            
            if (buttons[2].state())
            {
                resFreqScaleSlider.value((resFreqScaleSlider.max() - resFreqScaleSlider.min()) * msg.touchX + resFreqScaleSlider.min());
                resQSlider.value((resQSlider.max() - resQSlider.min()) * msg.touchY  + resQSlider.min());
            }
            else if (buttons[1    ].state())
            {
                delayDurationSlider.value((delayDurationSlider.max() - delayDurationSlider.min()) * msg.touchX + delayDurationSlider.min());      
                feedbackGainSlider.value((feedbackGainSlider.max() - feedbackGainSlider.min()) * msg.touchY + feedbackGainSlider.min());
            }
            
            //<<< msg.which, msg.touchX, msg.touchY, msg.touchSize >>>;
            //sounders[msg.which].set(msg.touchX, msg.touchY, msg.touchSize);
        }
    }
}



// inifinite loop
while (1)
{
    1::week => now;
} 