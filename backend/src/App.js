import React, { Fragment } from 'react';
import {
  CssBaseline,
  withStyles,
} from '@material-ui/core';

import AppHeader from './components/AppHeader';
import DiamondList from './components/DiamondList';

const styles = theme => ({
  main: {
    padding: theme.spacing(3),
    [theme.breakpoints.down('xs')]: {
      padding: theme.spacing(2),
    },
 },
});

const App = ({ classes }) => (
  <div>
    <CssBaseline />
    <AppHeader />
  </div>
);

export default withStyles(styles)(App);
