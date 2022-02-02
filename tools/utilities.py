##   MAPD modA - Barone Francesco Pio
##  
##  This file contains some useful functions for the FIR analysis.
##


######  FIR COEFFICIENTS  ######


def tohex(val, nbits):  # this formats the coefficients as hex signed values (2s complement)
    return hex((val + (1 << nbits)) % (1 << nbits))

def print_vivado_coefficients(hs):
    print('\n==================== VHDL ====================')
    vhdl_array_name = 'ca'  # the name of the array used in vivado to set the coefficient values
    fil = 'lowpass' if is_lowpass else 'highpass'
    print(f'-- {taps} taps {fil}: cutoff {cutoff_frequency}Hz for {sampling_frequency}Hz sampling, {bit_scaling}-bit scaling')
    for ii, val in enumerate(hs):
        print(f'ca({ii}) <= X"{val[2:].zfill(2)}";  ', end = '')
        if ii%5==4: print('')
    print('\n======= copy and paste the above code in vivado ========')


######  PLOTTER & SAMPLE MANAGEMENT  ######

def gen_time(lo,hi,freq): return np.linspace(lo,hi,(hi-lo)*freq)

def scaler(sig, waveform):
    print(len(waveform),'samples generated')
    print('The peak value is',  max(abs(waveform)) )
    fact = 100/max(abs(waveform)) # to keep the amplitude within the 8bit signed limits!
    print('I will scale the waveform of a factor', fact)
    sig = sig *fact
    waveform = waveform*fact
    return sig, waveform

def plot_waveform(x, sig, waveform, title=False):
    plt.figure( figsize=(8,4), dpi=80 )
    plt.plot( x, waveform, label='waveform', color = 'g', alpha = 0.7)
    plt.plot( x, sig, label='wave (noiseless)', color = 'k')
    plt.xlabel('time [s]'); plt.ylabel('strain');
    if title != False:
        plt.title(title)
    plt.legend(); plt.tight_layout(); plt.show();
    
    
    
# the samples are stored as a dictionary of dictionaries:
poll = {}
def add_to_poll(idd, sig, waveform):
    poll[idd] = { 'sig':sig, 'waveform':waveform}
    
    
# EOF