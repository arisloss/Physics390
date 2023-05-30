void plotResults() {

  const float max_deltaT = 2000.;//15000.;
  const float bins_deltaT = 100.;
  const float bins_intV = 200.;
  const float bins_intE = 100.;

  // 10k
  const float max_intV = 1.1;
  const float min_intV = 0.90;
  const float max_intE = 0.014;
  const float min_intE = 0.013;

  /*
  // 1k
  const float max_intV = 1.2;
  const float min_intV = 0.8;
  const float max_intE = 0.048;
  const float min_intE = 0.038;
  */


  TTree * t = new TTree("t","t");
  t->ReadFile("log_10k.dat","l0/C:index/I:l1/C:intV/F:l2/C:intE/F:l3/C:dt/I");
  //t->ReadFile("log_1k.dat","l0/C:index/I:l1/C:intV/F:l2/C:intE/F:l3/C:dt/I");
  t->Print();

  TCanvas * c0 = new TCanvas("c0","c0", 0, 0, 600, 500);
  TH1F* h0 = new TH1F("h0","h0",bins_deltaT,0,max_deltaT);
  t->Draw("dt>>h0", "dt<5e5", "goff");
  TH1F* f0 = (TH1F*)(c0->DrawFrame(0,0.1,max_deltaT,1.5*h0->GetMaximum()));
  f0->GetXaxis()->SetTitle("#Delta t [#mu s]");
  h0->SetLineColor(kBlue);
  h0->SetLineWidth(2);
  h0->Draw("sames");
  c0->SetLogy();

  TCanvas * c1 = new TCanvas("c1","c1", 600, 0, 600, 500);
  TH1F* h1 = new TH1F("h1","h1",bins_intV,min_intV,max_intV);
  t->Draw("intV>>h1", "", "goff");
  TH1F* f1 = (TH1F*)(c1->DrawFrame(min_intV,0.1,max_intV,1.1*h1->GetMaximum()));
  f1->GetXaxis()->SetTitle("integral");
  h1->SetLineColor(kBlue);
  h1->SetLineWidth(2);
  h1->Draw("sames");


  TCanvas * c2 = new TCanvas("c2","c2", 1200, 0, 600, 500);
  TH1F* h2 = new TH1F("h2","h2",bins_intE,min_intE,max_intE);
  t->Draw("intE>>h2", "", "goff");
  TH1F* f2 = (TH1F*)(c2->DrawFrame(min_intE,0.1,max_intE,1.1*h2->GetMaximum()));
  f2->GetXaxis()->SetTitle("error");
  h2->SetLineColor(kBlue);
  h2->SetLineWidth(2);
  h2->Draw("sames");


}
