 printf("Pending signal\n");
  if(p->Sigactions[signum].sa_handler==(void*)SIG_IGN)
  {
    //Ignore
    return;
  }
  printf("Q\n");
  if(p->Sigactions[signum].sa_handler==(void*)SIG_DFL)
  {
    defaultHandlerForSignal(p, signum);
  }
  printf("w\n");
  if(p->Sigactions[signum].sa_handler==(void*)SIGKILL)
  {
    killprocess(p);
  }
  printf("e\n");
  if(p->Sigactions[signum].sa_handler==(void*)SIGSTOP)
  {
    stopprocess(p);
  }
  printf("r\n");
  if(p->Sigactions[signum].sa_handler==(void*)SIGCONT)
  {
    contprocess(p);
  }
  //else{
    //Set mask from handler
    printf("A\n");
    uint prevMask=p->SignalMask;
    printf("B\n");
    struct sigaction* action=&(p->Sigactions[signum]);
    printf("C\n");
    uint tempMask=action->sigmask;
    printf("D\n");
    p->SignalMask=tempMask;
    printf("E\n");
    handldeUserHandler(p, signum);
    p->SignalMask=prevMask;
  //}

  p->PendingSignals = p->PendingSignals^(1<<signum);