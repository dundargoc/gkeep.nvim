

function! health#gkeep#check()
  call gkeep#preload()
  call health#report_start('gkeep')
  if !has('python3')
    call health#report_error('Python provider error:', ["gkeep requires python3", "Run :checkhealth provider for more info"])
    return
  endif

  python3 import sys
  let exe = py3eval('sys.executable')
  let [ok, error] = provider#pythonx#CheckForModule(exe, 'gkeepapi', 3)
  if !ok
    call health#report_error(error)
  else
    python3 import gkeepapi
    let l:version = py3eval('gkeepapi.__version__')
    call health#report_ok("gkeepapi " . l:version . " installed")
    python3 import gpsoauth
    let l:version = py3eval('gpsoauth.__version__')
    call health#report_ok("gpsoauth " . l:version . " installed")
    python3 import urllib3
    let l:version = py3eval('urllib3.__version__')
    call health#report_ok("urllib3 " . l:version . " installed")
  endif
  let [ok, error] = provider#pythonx#CheckForModule(exe, 'keyring', 3)
  if !ok
    call health#report_error(error)
  else
    call health#report_ok("keyring installed")
  endif

  if exists(':GkeepLogin') != 2
    call health#report_error('Remote plugin not found', 'Try running :UpdateRemotePlugins and restart')
    return
  endif

  let health = _gkeep_health()

  if health.logged_in
    call health#report_ok('Logged in as ' . health.email)
  elseif health.has_token
    call health#report_warn('Not logged in but auth token exists', 'Try :GkeepOpen')
  else
    call health#report_warn('Not logged in', 'Try :GkeepLogin')
  endif

  if !empty(health.sync_dir)
    call health#report_info("Syncing notes to " . health.sync_dir)
  endif
  if health.support_neorg
    call health#report_ok("Neorg support enabled")
  endif
  if !empty(health.keyring_err)
    call health#report_error("Error with keyring provider: " . health.keyring_err, 'See https://github.com/stevearc/gkeep.nvim/issues/8')
  endif

  let status = GkeepStatus()
  if !empty(status)
    call health#report_info(status)
  endif
  call health#report_info("Log file: " . stdpath('cache') . '/gkeep.log')
endfunction
