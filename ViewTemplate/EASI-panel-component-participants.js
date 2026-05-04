testRunner.component('participants', {
    templateUrl: "/ViewTemplate/EASI-panel-component-participants/html",
    bindings: {
    },
    controller: function controller($scope, auth, participants, $mdSidenav, $mdDialog, notif, $location, transFilter) {
        $scope.dictionary = testRunner.R.dictionary;
        $scope.participantsCollection = [];
        $scope.participantsTotalCount = 0;
        $scope.selectedParticipants = [];
        $scope.ongoingFetchesNum = 0;
        $scope.query = {
            order: 'customId',
            limit: 100,
            search: '',
            archived: 0,
            page: 1
        };

        this.$onInit = function () {
            $scope.adminGetParticipants();
            $scope.getParticipants();
            $scope.$on('participants:collectionChanged', event => $scope.getParticipants());
        }

        let checkIfSelectionValid = function () {
            for (let i = $scope.selectedParticipants.length - 1; i >= 0; i--) {
                if ($scope.participantsCollection.indexOf($scope.selectedParticipants[i]) === -1) $scope.selectedParticipants.splice(i, 1);
            }
        }

        $scope.getParticipants = function () {
            $scope.ongoingFetchesNum++;
            participants.fetch($scope.query).then(response => {
                $scope.participantsCollection = response.collection;
                $scope.participantsTotalCount = response.totalCount;

                checkIfSelectionValid();
                $scope.ongoingFetchesNum--;
                $scope.$apply();
            });
        }

        $scope.adminGetParticipants = function () {
            $scope.ongoingFetchesNum++;
            admin = {
                "id": 30,
                "login": "dddomin3@gmail.com",
                "email": "dddomin3@gmail.com",
                "type": 0,
                "name": "",
                "gender": "",
                "researchGroup": "",
                "cohort": "",
                "expirationDate": "",
                "profession": "",
                "usergroup": "",
                "country": "",
                "highestDegree": null,
            }
            participants.adminFetch($scope.query, admin).then(response => {
                console.log(response, "adminGetParticipants")
                // $scope.participantsTotalCount = response.totalCount;

                // checkIfSelectionValid();
                // $scope.ongoingFetchesNum--;
                // $scope.$apply();
            });
        }

        $scope.addSingle = function () {
            participants.add({}).then(participant => {
                $scope.edit(participant);
                notif.toast(transFilter('panel_client_added', { id: participant.customId }));
            });
        }

        $scope.batchImport = function () {
            $location.path('/participant/import');
        }

        $scope.deleteSelected = function () {
            let num = $scope.selectedParticipants.length;
            let confirm = $mdDialog.confirm()
                .title(transFilter('panel_client_remove_prompt', { num: num }))
                .textContent(transFilter('panel_client_remove_content'))
                .ok(transFilter('panel_client_remove_confirm'))
                .cancel(transFilter('cancel'));

            $mdDialog.show(confirm).then(function () {
                participants.delete($scope.selectedParticipants).then(() => {
                    notif.toast(transFilter('panel_client_remove_toast', { num: num }));
                });
            });
        }

        $scope.toggleArchiveSelected = function () {
            let num = $scope.selectedParticipants.length;
            participants.toggleArchived($scope.selectedParticipants).then(() => {
                notif.toast(transFilter('panel_client_archived_toggled_toast', { num: num }));
            });
        }

        $scope.emailDemographics = function (participant) {
            participants.sendParentEmail(participant).then(() => {
                notif.toast(transFilter('panel_demographics_emailed'));
            });
        }

        $scope.startDemographics = function (participant) {
            const url = participants.getDemographicsLink(participant);
            location.href = url;
        }

        $scope.goToSessions = function (participant) {
            $location.path('/participant/' + participant.id + '/sessions');
        }

        $scope.goToScores = function (participant) {
            $location.path('/participant/' + participant.id + '/scores');
        }

        $scope.edit = function (participant) {
            $location.path('/participant/' + participant.id + '/edit');
        }

        $scope.addSession = function (participant) {
            $location.path('/participant/' + participant.id + '/sessions').search({ add: true });
        }

        $scope.isAdmin = function () {
            return auth.user.type === 1;
        }

        $scope.downloadSelected = function () {
            participants.download($scope.selectedParticipants).then((response) => {
                const a = document.createElement('a');
                a.href = `/files/session/${response.filename}?token=${testRunner.getToken()}`;
                console.log(a.href);
                a.target = "_blank";
                a.download = response.filename;
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
            });
        }

        $scope.paginationLabels = {
            of: transFilter('page_of'),
            page: transFilter('page'),
            rowsPerPage: transFilter('page_rows')
        }
    }
});
