import { Link, Outlet } from 'react-router-dom';

import OceanBackground from './OceanBackground.jsx';

export default function Layout() {
  return (
    <div className="site">
      <OceanBackground />
      <header className="site-header">
        <Link to="/" className="site-brand">
          <span className="site-title">Unscholarly Questions</span>
          <span className="site-byline">by Hanyang Liu</span>
        </Link>
        <nav>
          <a href="mailto:hanyangfliu@gmail.com">email</a>
          <a href="https://hanyangliu.dev">← back to game</a>
        </nav>
      </header>
      <main>
        <Outlet />
      </main>
      <footer className="site-footer">
        © {new Date().getFullYear()} Hanyang Liu
      </footer>
    </div>
  );
}
