#define N_SAMPLE_SIZES 7
// adapted from plotCircleTrialsNaive.C

void
plotMyMaxwellTrialsNaive() {


  gStyle->SetOptStat(0);

  int trials=1000;
  char mystr[256]; // for histo name, file name, etc

  int sample_sizes[N_SAMPLE_SIZES]={ 10, 100, 1000, 10000, 100000, 1000000, 10000000 };
  EColor sample_color[N_SAMPLE_SIZES]={ kWhite, EColor(kOrange+7), kYellow, kGreen, kBlue, kMagenta, kRed };

  TH1F *  harr[N_SAMPLE_SIZES];  TTree * tarr[N_SAMPLE_SIZES]; TPaveStats * sarr[N_SAMPLE_SIZES];
  for( int i=0; i<N_SAMPLE_SIZES; i++ ) {

    sprintf(mystr, "h%d", sample_sizes[i]);
    if( i == 0 )
      harr[i] = new TH1F(mystr,mystr,100,0,6);
    else 
      harr[i] = new TH1F(mystr,mystr,100,0.9,1.1);

    sprintf(mystr, "t%d", sample_sizes[i]);    
    tarr[i] = new TTree(mystr,mystr);
    sprintf(mystr, "./data/maxwell_%d_samples_%d.dat", trials, sample_sizes[i]);    
    tarr[i]->ReadFile(mystr, "l0/C:area/F:l1/C:err/F:l2/C:trials/I");

    sprintf(mystr, "area>>h%d", sample_sizes[i]);
    tarr[i]->Draw(mystr,"","goff");
    //harr[i]->SetFillColor(kBlack);
    harr[i]->SetLineColor(sample_color[i]);
    harr[i]->SetLineWidth(2);
  }

  TCanvas * c = new TCanvas("c","c", 0, 0, 700, 600);
  c->SetFillColor(kBlack);
  TH1F* frame = (TH1F*)(c->DrawFrame(0.9,0.1,1.1,1.1*harr[N_SAMPLE_SIZES-1]->GetMaximum()));
  frame->SetName("myframe");
  frame->SetFillColor(kBlack);
  frame->GetXaxis()->SetTitle("area");
  frame->GetXaxis()->SetAxisColor(kWhite);
  frame->GetXaxis()->SetLabelColor(kWhite);
  frame->GetXaxis()->SetTitleColor(kWhite);
  frame->GetYaxis()->SetTitle("Counts");
  frame->GetYaxis()->SetAxisColor(kWhite);
  frame->GetYaxis()->SetLabelColor(kWhite);
  frame->GetYaxis()->SetTitleColor(kWhite);

  TLegend * l = new TLegend(0.65,0.7, 0.95,0.95);
  l->SetFillColor(kBlack);
  l->SetTextColor(kWhite);

  for( int i=0; i<N_SAMPLE_SIZES; i++ ) { 

    cout << "samples: " << sample_sizes[i] << "\t"
	 << "mean: " << harr[i]->GetMean() << "\t"
	 << "rms: " << harr[i]->GetRMS() << "\t" 
	 << "err: " << tarr[i]->GetMinimum("err") << "\t"
	 << "trials: " << harr[i]->GetEntries()  << "\t"
	 << endl;

    if( i>0 ) harr[i]->Draw("hsame");

    sprintf(mystr, "n=%d, #sigma=%f", sample_sizes[i], harr[i]->GetRMS());
    l->AddEntry(harr[i],mystr,"l");

    //sarr[i] = (TPaveStats*)(harr[i]->GetListOfFunctions()->FindObject("stats"));
    //sarr[i]->SetFillColor(kBlack);
    //sarr[i]->SetTextColor(sample_color[i]);
  }

  c->Modified();
  frame->SetFillColor(kBlack);
  l->Draw("same");
  c->SetLogy();
  c->Update();
  c->Modified();


  //
  // now plot error scaling
  //

  vector<double> n_vals, rms_vals, sem_vals;
  for( int i=0; i<N_SAMPLE_SIZES; i++ ) { 
    n_vals.push_back(tarr[i]->GetMinimum("trials"));
    rms_vals.push_back(harr[i]->GetRMS());
    sem_vals.push_back(tarr[i]->GetMinimum("err"));
  }
  
  TGraph * g_rms = new TGraph((Int_t) n_vals.size(), (double*)&(n_vals[0]), (double*)&(rms_vals[0]));
  TGraph * g_sem = new TGraph((Int_t) n_vals.size(), (double*)&(n_vals[0]), (double*)&(sem_vals[0]));
  TCanvas * cc = new TCanvas("cc","cc",6-0,0,600,500);
  TH1F* fframe = (TH1F*)(cc->DrawFrame(0.1,
				       0.1*TMath::MinElement(g_rms->GetN(),g_rms->GetY()),
				       1.5*TMath::MaxElement(g_rms->GetN(),g_rms->GetX()),
				       1.5*TMath::MaxElement(g_rms->GetN(),g_rms->GetY())));

  cout << "minY: " << 0.1*TMath::MinElement(g_rms->GetN(),g_rms->GetY()) << endl;
  cout << "maxX: " << 1.5*TMath::MaxElement(g_rms->GetN(),g_rms->GetX()) << endl;
  cout << "maxY: " << 1.5*TMath::MaxElement(g_rms->GetN(),g_rms->GetY()) << endl;



  TLegend * leg = new TLegend(0.7,0.6,0.9,0.9);
  leg->SetTextSize(0.05);

  g_rms->SetMarkerColor(kBlue);
  g_rms->SetMarkerStyle(20);
  g_rms->SetMarkerSize(1.2);
  g_rms->Print();
  leg->AddEntry(g_rms,"#sigma_{means}","p");
  

  g_sem->SetLineColor(kRed);
  g_sem->SetLineWidth(2);
  g_sem->Print();
  leg->AddEntry(g_sem,"#frac{#sigma_{sample}}{#sqrt{N}}","l");

  cc->SetLogy();
  cc->SetLogx();
  g_sem->Draw("l");
  g_rms->Draw("p");
  leg->Draw("same");


}
