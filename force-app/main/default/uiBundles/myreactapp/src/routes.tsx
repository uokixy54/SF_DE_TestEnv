import type { RouteObject } from 'react-router';
import AppLayout from '@/appLayout';
import Home from './pages/Home';
import Accounts from './pages/Accounts';
import NotFound from './pages/NotFound';

export const routes: RouteObject[] = [
  {
    path: '/',
    element: <AppLayout />,
    children: [
      {
        index: true,
        element: <Home />,
        handle: { showInNavigation: true, label: 'Home' },
      },
      {
        path: 'accounts',
        element: <Accounts />,
        handle: { showInNavigation: true, label: '取引先' },
      },
      {
        path: '*',
        element: <NotFound />,
      },
    ],
  },
];
